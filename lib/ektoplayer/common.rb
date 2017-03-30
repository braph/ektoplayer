require 'thread'
require 'open3'

class Dir
   def Dir.size(path)
      Dir.glob(File.join(path, '**', ?*)).map(&File.method(:size)).sum
   end
end

module Common
   def self.open_url_extern(url)
      if url =~ /\.(jpe?g|png)$/i
         Common.open_image_extern(url)
      else
         fork { exec('xdg-open', url) }
      end
   end

   def self.open_image_extern(url)
      fork do
         exec('feh', url) rescue (
            exec('display', url) rescue (
               exec('xdg-open', url)
            )
         )
      end
   end
   
   def self.extract_zip(zip_file, dest)
      absolute_path = File.absolute_path(zip_file)
      # try 'unzip'
      out, err, status = Open3.capture3('unzip', absolute_path, chdir: dest)
      fail err unless status.exitstatus == 0
   rescue Errno::ENOENT
      # try '7zip'
      out, err, status = Open3.capture3('7z', ?x, absolute_path, chdir: dest)
      fail err unless status.exitstatus == 0
   rescue Errno::ENOENT
      # try RubyZip gem
      require 'zip'

      Zip::File.open(absolute_path) do |zip_obj|
         zip_obj.each do |f|
            f.extract(File.join(dest, f.name))
         end
      end
   rescue LoadError
      fail 'neither RubzZip gem nor /bin/unzip or /bin/7z found'
   rescue
      Ektoplayer::Application.log(self, "error extracting zip", zip_file, dest, $!)
   end

   def self.with_hash_zip(keys, values)
      hash = {}

      keys.size.times do |i|
         hash[keys[i]] = values[i]
      end

      yield hash

      keys.clear << hash.keys
      values.clear << hash.values
   end

   def self.to_time(secs)
      return '00:00' unless secs or secs == 0
      "%0.2d:%0.2d" % [(secs / 60), (secs % 60)]
   end

   def self.mksingleton(cls)
      unless cls.singleton_methods.include? :_get_instance
         cls.define_singleton_method(:_get_instance) do
            unless cls.class_variable_defined? :@@_class_instance
               cls.class_variable_set :@@_class_instance, cls.new
            end

            cls.class_variable_get :@@_class_instance
         end

         (cls.instance_methods - Object.instance_methods).each do |method|
            cls.define_singleton_method(method) do |*args|
               cls._get_instance.send(method, *args)
            end
         end
      end
   end
end

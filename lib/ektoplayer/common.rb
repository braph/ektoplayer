require 'zip'

class Object
   alias :frz :freeze
end

class Dir
   def Dir.size(path)
      Dir.glob(File.join(path, '**', ?*)).map { |f| File.size(f) }.sum
   end
end

class String
   def chunks(n)
      return [self] if n < 1

      if (chunk_size = self.size / n) < 1
         return [self]
      end

      (n - 1).times.map do |i|
         self.slice((chunk_size * i)..(chunk_size * (i + 1) - 1))
      end + [
         self.slice((chunk_size * (n-1))..-1)
      ]
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
         begin exec('feh', url)
         rescue
            begin exec('display', url)
            rescue 
               exec('xdg-open', url)
            end
         end
      end
   end

   def self.extract_zip(zip_file, dest)
      Zip::File.open(zip_file) do |zip_obj|
         zip_obj.each do |f|
            f.extract(File.join(dest, f.name))
         end
      end
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

require 'open3'
require 'uri'

require_relative '../events'

class ExternalDownload
   attr_reader :events, :url, :progress, :filename, :error

   def initialize(url, filename)
      @events   = Events.new(:completed, :failed)
      @url      = URI.parse(url)
      @filename = filename
      @progress = 0
      @error    = nil
      @tries    = 3
   end

   def self.get_wget_cmd(url, file)
      %w(wget -nv --show-progress --progress=dot:binary -O) + [file, url]
   end

   def self.get_curl_cmd(url, file)
      %w(curl -# -o) + [file, url]
   end

   def start!
      Thread.new do
         args = CMD.(@url.to_s, @filename)
         dl_in, dl_out, dl_err, @dl_proc = Open3.popen3(*args)

         begin
            while (line = dl_err.readpartial(1024))
               @last_line = line

               if (progress = line.scan(/(\d+(\.\d+)?%)/)[0][0].delete(?%).to_f rescue nil)
                  @progress = progress
               end
            end
         rescue
            nil
         end

         begin
            @dl_proc.join
            raise if @dl_proc.value.exitstatus > 0
            @progress = 100.0
            @events.trigger(:completed)
         rescue
            @events.trigger(:failed, (@error = @last_line))
         end
      end

      sleep 0.1 while @dl_proc.nil?
      sleep 0.2
      self
   end

   if system('wget --version >/dev/null 2>/dev/null')
      CMD = method :get_wget_cmd
   elsif system('curl --version >/dev/null 2>/dev/null')
      CMD = method :get_curl_cmd
   else
      fail LoadError, 'wget/curl not installed'
   end
end

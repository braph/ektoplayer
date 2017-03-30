require 'net/https'
require 'uri'

require_relative '../events'

class RubyDownload
   attr_reader :events, :url, :filename, :error

   def initialize(url, filename)
      @events   = Events.new(:completed, :failed)
      @url      = URI.parse(url)
      @filename = filename
      @bytes_read = 0
      @error, @total = nil, nil
      @tries    = 3
   end

   def progress
      (@bytes_read.to_f / @total * 100) rescue 0).clamp(0, 100).to_f
   end

   def start!
      Thread.new do
         success = false

         @tries.times do |try|
            begin
               do_download
               @events.trigger(:completed)
               success = true
               break
            rescue
               @_lasterror = $!
               sleep 3
            end
         end

         unless success
            @events.trigger(:failed, @_lasterror)
         end
      end

      sleep 0.1 while @total.nil?
      sleep 0.2
      self
   end

   private def do_download
      @file = File.open(filename, ?w)
      @bytes_read, @total, @error = 0, nil, nil

      http = Net::HTTP.new(@url.host, @url.port)

      http.request(Net::HTTP::Get.new(@url.request_uri)) do |res|
         fail res.body unless res.code == '200'

         @total = res.header['Content-Length'].to_i

         res.read_body do |chunk|
            @bytes_read += chunk.size
            @file << chunk
         end
      end

      fail 'filesize mismatch' if @bytes_read != @total
   ensure
      (@file.close rescue nil) if @file
   end
end

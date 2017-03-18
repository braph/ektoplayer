require 'fileutils'
require 'net/https'
require 'uri'

require_relative 'events'
require_relative 'common'

module Ektoplayer
   class Trackloader
      attr_reader :downloads

      def initialize(database)
         @downloads = []
         @database = database
      end

      def get_track_infos(url)
         r = @database.select(filters: [{tag: :url, operator: :==, value: url}])[0]

         r.update(
            @database.get_archives(url).select {|_|_['archive_type'] == 'MP3'}[0]
         )

         r['archive_filename'] = URI.unescape(File.basename(URI.parse(r['archive_url']).path))
         r['archive_basename'] = File.basename(r['archive_filename'], '.zip')
         r['album_path'] = File.join(Config[:archive_dir], r['archive_basename'])
         r
      end

      def download_album(url)
         track_info = get_track_infos(url)
         return if File.exists? track_info['album_path']

         archive_file = File.join(Config[:download_dir], track_info['archive_filename'])
         return if File.exists? archive_file

         dl = DownloadThread.new(track_info['archive_url'], archive_file)

         if Config[:auto_extract_to_archive_dir]
            dl.events.on(:completed) do 
               begin
                  extract_dir = track_info['album_path']
                  FileUtils::mkdir_p(extract_dir)
                  Common::extract_zip(archive_file, extract_dir)
                  FileUtils::rm(archive_file) if Config[:delete_after_extraction]
               rescue => e
                  Application.log(self.class, 'extract failed', archive_file, extract_dir, e)
               end
            end
         end

         dl.events.on(:failed) do |reason|
            Application.log(self.class, dl.file, dl.url, reason)
            FileUtils::rm(dl.file) rescue nil
         end

         @download << dl.start!
      end

      def get_track_file(url, reload: false)
         begin
            track_info = get_track_infos(url)
            album_files = Dir.glob(File.join(track_info['album_path'], '*.mp3'))
            track_file = album_files.sort[track_info['number']]
            return track_file if track_file
         rescue => e
            Application.log(self.class, 'could not load track from archive_dir', e)
         end

         url_obj    = URI.parse(url)
         basename   = File.basename(url_obj.path)
         cache_file = File.join(Config[:cache_dir], basename)
         temp_file  = File.join(Config[:temp_dir], basename)

         (File.delete(cache_file) rescue nil) if reload
         (File.delete(temp_file)  rescue nil) if reload

         return cache_file if File.file?(cache_file)
         return temp_file  if File.file?(temp_file)

         dl = DownloadThread.new(url, temp_file)

         if Config[:use_cache]
            dl.events.on(:completed) do 
               begin FileUtils::mv(temp_file, cache_file)
               rescue => e
                  Application.log(self.class, 'mv failed', temp_file, cache_file, e)
               end
            end
         end

         dl.events.on(:failed) do |reason|
            Application.log(self.class, dl.file, dl.url, reason)
            FileUtils::rm(dl.file) rescue nil
         end

         @downloads << dl.start!

         return temp_file
      end
   end

   class DownloadThread
      attr_reader :events, :url, :progress, :total, :file, :filename, :error

      def initialize(url, filename)
         @events   = Events.new(:completed, :failed, :progress)
         @url      = URI.parse(url)
         @filename = filename
         @file     = File.open(filename, ?w)
         @progress = 0
         @error    = nil
      end

      def start!
         Thread.new do
            begin
               http = Net::HTTP.new(@url.host, @url.port)

               http.request(Net::HTTP::Get.new(@url.request_uri)) do |res|
                  fail res.body unless res.code == '200'

                  @total = res.header['Content-Length'].to_i

                  res.read_body do |chunk|
                     @progress += chunk.size
                     @events.trigger(:progress, @progress)
                     @file << chunk
                  end
               end

               fail 'filesize mismatch' if @progress != @total
               @events.trigger(:completed)
            rescue => e
               @events.trigger(:failed, (@error = e))
            ensure
               @file.close
            end
         end

         sleep 0.1 while @total.nil?
         sleep 0.1
         self
      end
   end
end

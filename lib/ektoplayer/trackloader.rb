require 'fileutils'
require 'uri'
require 'cgi'

require_relative 'common'

begin
   require_relative 'download/externaldownload'
   DownloadThread = ExternalDownload
rescue LoadError
   require_relative 'download/rubydownload'
   DownloadThread = RubyDownload
end

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

         r['archive_filename'] = CGI.unescapeURIComponent(r['archive_url'])
         r['archive_basename'] = File.basename(r['archive_filename'], '.zip')
         r['album_path'] = File.join(Config[:archive_dir], r['archive_basename'])
         r
      end

      def download_album(url)
         track_info = get_track_infos(url)
         return if File.exists? track_info['album_path']

         archive_file = File.join(Config[:download_dir], track_info['archive_filename'])
         return if File.exists? archive_file

         archive_url = Application.archive_url(track_info['archive_url'])
         Application.log(self, 'starting download:', archive_url)
         dl = DownloadThread.new(archive_url, archive_file)

         if Config[:auto_extract_to_archive_dir]
            dl.events.on(:completed) do 
               begin
                  extract_dir = track_info['album_path']
                  FileUtils::mkdir_p(extract_dir)
                  Common::extract_zip(archive_file, extract_dir)
                  FileUtils::rm(archive_file) if Config[:delete_after_extraction]
               rescue
                  Application.log(self, "extraction of '#{archive_file}' to '#{extract_dir}' failed:", $!)
               end
            end
         end

         dl.events.on(:failed) do |reason|
            Application.log(self, dl.filename, dl.url, reason)
            FileUtils::rm(dl.filename) rescue nil
         end

         @downloads << dl.start!
      rescue
         Application.log(self, $!)
      end

      def get_track_file(url, reload: false, http_okay: false)
         begin
            track_info = get_track_infos(url)
            album_files = Dir.glob(File.join(track_info['album_path'], '*.mp3'))
            track_file = album_files.sort[track_info['number']]
            return track_file if track_file
         rescue
            Application.log(self, 'could not load track from archive_dir:', $!)
         end

         real_url   = Application.track_url(url)
         url_obj    = URI.parse(real_url)
         basename   = File.basename(url_obj.path)
         cache_file = File.join(Config[:cache_dir], basename)
         temp_file  = File.join(Config[:temp_dir], '~ekto-' + basename)

         (File.delete(cache_file) rescue nil) if reload
         (File.delete(temp_file)  rescue nil) if reload

         return cache_file if File.file?(cache_file)
         return temp_file  if File.file?(temp_file)
         return real_url   if http_okay

         Application.log(self, 'starting download:', real_url)
         dl = DownloadThread.new(real_url, temp_file)

         if Config[:use_cache]
            dl.events.on(:completed) do 
               FileUtils::mv(temp_file, cache_file) rescue (
                  Application.log(self, 'mv failed', temp_file, cache_file, $!)
               )
            end
         end

         dl.events.on(:failed) do |reason|
            Application.log(self, dl.filename, dl.url, reason)
            FileUtils::rm(dl.filename) rescue nil
         end

         @downloads << dl.start!

         return temp_file
      rescue
         Application.log(self, $!)
      end
   end
end

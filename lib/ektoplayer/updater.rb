require 'set'
require 'thread'
require 'open-uri'

require_relative 'browsepage'

module Ektoplayer
   MAIN_URL = 'http://www.ektoplazm.com'.freeze
   FREE_MUSIC_URL = "#{MAIN_URL}/section/free-music".freeze

   class DatabaseUpdater
      ALBUM_STR_TAGS = Set.new(%w(url title date category cover_url
            description download_count rating votes
            released_by released_by_url posted_by posted_by_url).map(&:to_sym)).freeze

      TRACK_STR_TAGS = Set.new(%w(url number title remix artist bpm).map(&:to_sym)).freeze

      def initialize(db)
         @db = db
      end

      def update(start_url: FREE_MUSIC_URL, pages: 0, parallel: 10)
         queue = parallel > 0 ? SizedQueue.new(parallel) : Queue.new 
         insert_browserpage(bp = BrowsePage.new(start_url))

         if pages > 0
            bp.page_urls[(bp.current_page_index + 1)..(bp.current_page_index + pages + 1)]
         else
            bp.page_urls[(bp.current_page_index + 1)..-1]
         end.
         each do |url|
            queue << Thread.new do
               insert_browserpage(BrowsePage.new(url))
               queue.pop # unregister our thread
            end
         end

         sleep 1 while not queue.empty?
      rescue Application.log(self, $!)
      end

      private def insert_browserpage(browserpage)
         browserpage.styles.each do |style, url|
            @db.replace_into(:styles, { style: style, url: url })
         end

         browserpage.albums.each { |album| insert_album album }
      rescue Application.log(self, $!)
      end

      private def insert_album(album)
         album_r = ALBUM_STR_TAGS.map { |tag| [tag, album[tag]] }.to_h
         @db.replace_into(:albums, album_r)

         album[:styles].each do |style|
            @db.replace_into(:albums_styles, {
               album_url:  album[:url],
               style:      style
            })
         end

         album[:archive_urls].each do |type, url|
            @db.replace_into(:archive_urls, {
               album_url:    album[:url],
               archive_type: type,
               archive_url:  url
            })
         end

         album[:tracks].each do |track|
            track_r = TRACK_STR_TAGS.map { |tag| [tag, track[tag]] }.to_h
            track_r[:album_url] = album[:url]
            @db.replace_into(:tracks, track_r)
         end
      end
   end
end

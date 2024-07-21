#!/bin/ruby

require 'nokogiri'
require 'date'
require 'base64'
require 'scanf'
require 'uri'
require 'open-uri'

module Ektoplayer
   class BrowsePage
      ALBUM_KEYS = %w(url title artist date styles cover_url description download_count
                      archive_urls rating votes tracks).map(&:to_sym).freeze

      TRACK_KEYS = %w(url album_url number title remix artist bpm).map(&:to_sym).freeze

      attr_reader :albums, :page_urls, :current_page_index

      def self.from_url(url)
         BrowsePage.new(URI.open(url).read())
      end

      def styles;            @@styles or []   end
      def first_page_url;    @page_urls[0]    end
      def last_page_url;     @page_urls[-1]   end
      def current_page_url;  @page_urls[@current_page_index - 1] end

      def prev_page_url
         @page_urls[@current_page_index - 1] if @current_page_index > 0
      end

      def next_page_url
         @page_urls[@current_page_index + 1] if @current_page_index + 1 < @page_urls.size
      end

      def initialize(src)
         doc = Nokogiri::HTML(src)
         @albums = []

         base_url = doc.css('.wp-pagenavi a')[0]['href'].sub(/\d+$/, '')
         pages = doc.css('.wp-pagenavi .pages')[0].text # -> "Page 1 of 22"
         @current_page_index, last = pages.gsub(/[^\d ]/, '').split()
         @current_page_index, last = @current_page_index.to_i, last.to_i
         @page_urls = (1..last).map do |i| "#{base_url}#{i}" end

         @@styles ||= begin
            doc.xpath('//a[contains(@href, "http") and contains(@href, "/style/")]').map do |a|
               [ a.text, File.basename(a['href']) ]
            end.to_h
         end

         doc.xpath('//div[starts-with(@id, "post-")]').each do |post|
            album = { tracks: [] }
            album[:date] = Date.parse(post.at_css('.d').text).iso8601 rescue nil

            album[:styles] = []
            post.css('.style a').map do |a|
               @@styles[a.text] = File.basename(a['href'])
               album[:styles] << a.text
            end

            album[:description] = post.at_css(?p).
               to_html.sub(/^<p>/, '').sub(/<\/p>$/, '') rescue ''

            begin album[:cover_url] = File.basename(
               URI.parse(post.at_css('.cover')['src']).path
            )
            rescue
            end

            album[:download_count] = post.at_css('.dc strong').text.delete(?,).to_i rescue 0

            post.css('h1 a').each do |a|
               album[:title] = a.text
               album[:url] = File.basename(URI.parse(a['href']).path)
            end 

            album[:archive_urls] = post.css('.dll a').map do |a|
               [ a.text.split[0] , File.basename(a['href']) ]
            end.to_h

            begin
               post.at_css('.postmetadata .d').
                  text.scanf('Rated %f%% with %d votes').
                  each_slice(2) { |r,v| album[:rating], album[:votes] = r, v }
            rescue
               album[:rating], album[:votes] = 0, 0
            end

            # Extract audio file URLs
            tracklist_urls = []
            post.xpath('.//div').each do |div|
              soundFile = div.text.scan(/\[audio:([^\]].+)\]/)
               if soundFile.size > 0
                  soundFile = soundFile[0][0]
                  tracklist_urls = soundFile.split(?,)
                  tracklist_urls.map! { |url| File.basename(url) }
                  break
               end
            end
            #
            unless tracklist_urls.size > 0
               # Sometimes there are no tracks:
               # http://www.ektoplazm.com/free-music/dj-basilisk-the-colours-of-ektoplazm
               Application.log(self, "Found no tracks for #{album[:title]} on #{current_page_url}")
            end

            post.css('.tl').each do |album_track_list|
               track = nil
               album_track_list.css('span').each do |ti|
                  case ti['class']
                  when ?n 
                     album[:tracks] << track if track and track[:url]
                     track = { url: tracklist_urls.shift }
                     track[:number] = ti.text.to_i
                  when ?t then track[:title]  = ti.text
                  when ?a then track[:artist] = ti.text
                  when ?r then track[:remix]  = ti.text
                  when ?d then track[:bpm]    = ti.text.scan(/\d+/)[0].to_i rescue nil
                  end
               end

               album[:tracks] << track if track and track[:url]
            end

            # extract artist name out ouf album title, set missing artist on album tracks
            unless album[:tracks].all? { |t| t.key?(:artist) }
               if album[:title].include?' – '
                  album[:artist], album[:title] = album[:title].split(' – ', 2)
                  album[:tracks].each { |t| t[:artist] ||= album[:artist] }
               else
                  album[:tracks].each { |t| t[:artist] ||= 'Unknown Artist' }
               end
            end

            @albums << album
         end
      end
   end
end

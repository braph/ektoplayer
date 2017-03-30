require_relative '../ui/widgets'
require_relative '../theme'
require_relative '../common'

require 'nokogiri'

module Ektoplayer
   MIN_WIDTH        = 90
   START_HEADING    = 1
   START_TAG        = 3
   START_TAG_VALUE  = 20
   START_INFO       = 3
   START_INFO_VALUE = 26
   LINE_WRAP        = 65

   module Views
      class Info < UI::Pad
         def attach(player, playlist, trackloader, database)
            @player, @playlist, @trackloader, @database =
               player, playlist, trackloader, database

            Thread.new do
               loop { sleep 1; draw if visible? }
            end.priority=(-10)
         end

         def draw_heading(heading)
            @win.attrset(Theme[:'info.head'])
            @win.mvaddstr(@win.cury + 1, START_HEADING, heading)
         end

         def draw_tag(tag, value=nil)
            @win.attrset(Theme[:'info.tag'])
            @win.mvaddstr(@win.cury + 1, START_TAG, tag)

            @win.attrset(Theme[:'info.value'])
            @win.mvaddstr(@win.cury, START_TAG_VALUE, value.to_s)
         end
         
         def draw_info(string, value=nil)
            @win.attrset(Theme[:'info.tag'])
            @win.mvaddstr(@win.cury + 1, START_INFO, string)

            @win.attrset(Theme[:'info.value'])
            @win.mvaddstr(@win.cury, START_INFO_VALUE, value.to_s)
         end

         def draw_url(url, title=nil)
            title ||= url
            mevent = with_mouse_section_event do
               @win.attrset(Theme[:url])
               @win << title
            end
            mevent.on(ICurses::BUTTON1_CLICKED) do
               Common::open_url_extern(url)
            end
         end
         
         def draw_download(file, percent, error)
            @win.attrset(Theme[:'info.download.file'])
            @win.mvaddstr(@win.cury + 1, START_TAG, file)
            @win.addch(32) # ' '

            @win.attrset(Theme[:'info.download.percent'])
            @win.addstr(percent.to_s)

            if error
               @win.addch(32) # ' '
               @win.attrset(Theme[:'info.download.error'])
               @win.addstr(error.to_s)
            end
         end

         def draw
            return unless @player

            self.pad_size=(UI::Size.new(
               height: 200,
               width:  [@size.width, MIN_WIDTH].max
            ))

            mouse_section.clear
            @win.erase
            @win.move(0,0)

            if @track = (@playlist[@playlist.current_playing] rescue nil)
               draw_heading('Current track')
               draw_tag('Number', '%0.2d' % @track['number'])
               draw_tag('Title',  @track['title'])
               draw_tag('Remix',  @track['remix']) if @track['remix']
               draw_tag('Artist', @track['artist'])
               draw_tag('Album',  @track['album'])
               draw_tag('BPM',    @track['bpm'])
               draw_tag('Length', Common::to_time(@player.length))
               @win.next_line

               draw_heading('Current album')

               draw_tag('Album')
               draw_url(Application.album_url(@track['album_url']), @track['album'])
               draw_tag('Artist',       @track['album__artist']) if @track['album_artist']
               draw_tag('Date',         @track['date'])

               draw_tag('Styles',       @track['styles'].gsub(?,, ', '))
               draw_tag('Downloads',    @track['download_count'])
               draw_tag('Rating',  '%0.2d%% (%d Votes)' % [@track['rating'], @track['votes']])
               draw_tag('Cover')
               draw_url(Application.cover_url(@track['cover_url']), 'Cover')

               @win.next_line

               # -- description
               draw_heading('Description')
               line_length = START_TAG
               wrap_length = @size.width.clamp(1, LINE_WRAP)
               @win.move(@win.cury + 1, START_TAG)

               Nokogiri::HTML("<p>#{@track['description']}</p>").css(?p).each do |p|
                  p.children.each do |element|
                     if element['href']
                        if (line_length += element.text.size) > wrap_length
                           @win.move(@win.cury + 1, START_TAG)
                           line_length = START_TAG
                        end

                        @win.addch(32) # ' '
                        draw_url(element['href'], element.text.strip)
                     else
                        element.text.split(' ').each do |text|
                           if (line_length += text.size) > wrap_length
                              @win.move(@win.cury + 1, START_TAG)
                              line_length = START_TAG
                           end

                           @win.addch(32) # ' '
                           @win.attrset(Theme[:'info.description'])
                           @win.mv_left(1) if text =~ /^[\.,:;]$/ 
                           @win << text
                        end
                     end
                  end
               end

               @win.next_line
               # --/description
            end

            if not @trackloader.downloads.empty?
               draw_heading('Downloads')
               @trackloader.downloads.each do |dl|
                  name = File.basename(dl.filename)
                  percent = '%0.2f' % dl.progress
                  draw_download(name, "(#{percent}%)", dl.error)
               end
               @win.next_line
            end

            draw_heading('Player')
            draw_info('Version', Application::VERSION)
            draw_info('Tracks in database', @database.track_count)
            draw_info('Albums in database', @database.album_count)
            draw_info('Tracks in playlist', @playlist.size)
            draw_info('Cache dir size', '%dMB' % (Dir.size(Config[:cache_dir]) / (1024 ** 2) rescue 0))
            draw_info('Archive dir size', '%dMB' % (Dir.size(Config[:archive_dir]) / (1024 ** 2) rescue 0))
            draw_info('Ektoplazm URL'); draw_url(Application::EKTOPLAZM_URL)
            draw_info('Github URL'); draw_url(Application::GITHUB_URL)

            self.pad_size=(@size.update(height: [@win.cursor.y + 2, @size.height].max))
            noutrefresh
         end
      end
   end
end


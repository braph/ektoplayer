require_relative '../ui/widgets'
require_relative '../bindings'
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
         def attach(playlist, trackloader, database)
            @playlist, @trackloader, @database = playlist, trackloader, database

            Thread.new do
               loop { sleep 1; with_lock { want_redraw } }
            end
         end

         def draw_heading(heading)
            @win.with_attr(Theme[:'info.head']) do
               @win.next_line.from_left(START_HEADING).addstr(heading)
            end
         end

         def draw_tag(tag, value=nil)
            @win.with_attr(Theme[:'info.tag']) do
               @win.next_line.from_left(START_TAG).addstr(tag)
            end

            @win.from_left(START_TAG_VALUE)
            @win.with_attr(Theme[:'info.value']) do
               @win.addstr("#{value}")
            end
         end
         
         def draw_info(string, value=nil)
            @win.with_attr(Theme[:'info.tag']) do
               @win.next_line.from_left(START_INFO).addstr(string)
            end

            @win.from_left(START_INFO_VALUE)
            @win.with_attr(Theme[:'info.value']) do
               @win.addstr("#{value}")
            end
         end

         def draw_url(url, title=nil)
            title ||= url
            mevent = with_mouse_section_event do
               @win.with_attr(Theme[:url]) { @win << title }
            end
            mevent.on(Curses::BUTTON1_CLICKED) do
               Common::open_url_extern(url)
            end
         end
         
         def draw_download(file, percent, error)
            @win.with_attr(Theme[:'info.download.file']) do
               @win.next_line.from_left(START_TAG).addstr(file)
            end
            @win.with_attr(Theme[:'info.download.percent']) do
               @win.addstr(" #{percent}")
            end

            if error
               @win.with_attr(Theme[:'info.download.error']) do
                  @win.addstr(" #{error}")
               end
            end
         end

         def with_mouse_section_event
            start_cursor = @win.cursor; yield

            start_pos = UI::Point.new(
               y: [start_cursor.y, @win.cursor.y].min,
               x: [start_cursor.x, @win.cursor.x].min,
            )
            stop_pos = UI::Point.new(
               y: [start_cursor.y, @win.cursor.y].max,
               x: [start_cursor.x, @win.cursor.x].max
            )

            ev = UI::MouseSectionEvent.new(start_pos, stop_pos)
            mouse_section.add(ev)
            ev
         end

         def mouse_click(mevent)
            if ev = mouse_event_transform(mevent)
               ev.x += @pad_mincol
               ev.y += @pad_minrow
               trigger(@mouse, ev)
               trigger(@mouse_section, ev)
            end
         end

         def draw
            self.pad_size=(UI::Size.new(
               height: 200,
               width:  [@size.width, MIN_WIDTH].max
            ))

            mouse_section.clear
            @win.erase
            @win.setpos(0,0)

            if @track = (@playlist[@playlist.current_playing] rescue nil)
               draw_heading('Current track')
               draw_tag('Number', "%0.2d" % @track['number'])
               draw_tag('Title',  @track['title'])
               draw_tag('Remix',  @track['remix']) if @track['remix']
               draw_tag('Artist', @track['artist'])
               draw_tag('Album',  @track['album'])
               draw_tag('BPM',    @track['bpm'])
               draw_tag('Length', Common::to_time(@length))
               @win.next_line

               draw_heading('Current album')
               draw_tag('Album'); draw_url(@track['album_url'], @track['album'])
               draw_tag('Artist',       @track['album__artist']) if @track['album_artist']
               draw_tag('Date',         @track['date'])

               if url = @track['released_by_url']
                  draw_tag('Released by'); draw_url(url, @track['released_by'])
               end

               if url = @track['posted_by_url']
                  draw_tag('Posted by');   draw_url(url, @track['posted_by'])
               end

               draw_tag('Styles',       @track['styles'].sub(?,, ', '))
               draw_tag('Downloads',    @track['download_count'])
               draw_tag('Rating',  "%0.2d%% (%d Votes)" % [@track['rating'], @track['votes']])
               draw_tag('Cover'); draw_url(@track['cover_url'], 'Cover')
               @win.next_line

               # -- description
               draw_heading('Description')
               line_length = START_TAG
               wrap_length = @size.width.clamp(1, LINE_WRAP)
               @win.next_line.from_left(START_TAG)

               Nokogiri::HTML("<p>#{@track['description']}</p>").css(?p).each do |p|
                  p.children.each do |element|
                     if element[:href]
                        if (line_length += element.text.size) > wrap_length
                           @win.next_line.from_left(START_TAG)
                           line_length = START_TAG
                        end

                        draw_url(element[:href], element.text.strip)
                        @win.addch(' ')
                     else
                        element.text.split(' ').each do |text|
                           if (line_length += text.size) > wrap_length
                              @win.next_line.from_left(START_TAG)
                              line_length = START_TAG
                           end

                           @win.with_attr(Theme[:'info.description']) do
                              @win.mv_left(1) if text =~ /^[\.,:;]$/ 
                              @win << text
                              @win << ' '
                           end
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
                  percent = Float(dl.progress) / dl.total * 100
                  percent = "%0.2f" % percent
                  draw_download(name, ?( + percent + '%)', dl.error)
               end
               @win.next_line
            end

            draw_heading('Player')
            draw_info('Version', Application::VERSION)
            draw_info('Tracks in database', @database.track_count)
            draw_info('Albums in database', @database.album_count)
            draw_info('Cache dir size', "%dMB" % (Dir.size(Config[:cache_dir]) / (1024 ** 2)))
            draw_info('Archive dir size', "%dMB" % (Dir.size(Config[:archive_dir]) / (1024 ** 2)))
            draw_info('Ektoplazm URL'); draw_url(Application::EKTOPLAZM_URL)
            draw_info('Github URL'); draw_url(Application::GITHUB_URL)

            self.pad_size=(@size.update(height: [@win.cursor.y + 2, @size.height].max))
         end
      end
   end
end

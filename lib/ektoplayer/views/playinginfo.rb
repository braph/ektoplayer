require_relative '../ui/widgets'
require_relative '../theme'
require_relative '../config'
require_relative '../common'

module Ektoplayer
   module Views
      class PlayingInfo < UI::Window
         STOPPED_HEADING = '- Ektoplayer -'.freeze

         def paused!
            return if @state == :paused
            with_lock { @state = :paused; want_redraw }
         end

         def playing!
            return if @state == :playing
            with_lock { @state = :playing; want_redraw }
         end

         def stopped!
            return if @state == :stopped
            with_lock { @state = :stopped; want_redraw }
         end

         def track=(t)
            return if @track == t
            with_lock { @track = t; want_redraw }
         end

         def length=(l)
            return if @length == l.to_i
            @length = l.to_i
            draw_position_and_length
         end

         def position=(p)
            return if @position == p.to_i
            @position = p.to_i
            draw_position_and_length
         end

         def draw_position_and_length
            return unless visible?
            @win.setpos(0,0)
            @win.with_attr(Theme[:'playinginfo.position']) do
               @win << "[#{Common::to_time(@position)}/#{Common::to_time(@length)}]" 
            end
            @win.refresh
         end

         def attach(playlist, player)
            player.events.on(:pause)  { self.paused!  }
            player.events.on(:stop)   { self.stopped! }
            player.events.on(:play)   { self.playing! }

            player.events.on(:position_change) do
               self.position=(player.position)
               self.length=(player.length)
            end

            playlist.events.on(:current_changed) {
               self.track=(playlist[playlist.current_playing])
            }

            # TODO: move mouse?
            self.mouse.on(Curses::BUTTON1_CLICKED) do |mevent|
               player.toggle
            end
         end
         
         private def fill(format)
            sum = 0
            format.each do |fmt|
               if fmt[:tag] == 'text' 
                  fmt[:filled] = fmt[:text]
               elsif value = @track[fmt[:tag]]
                  fmt[:filled] = value.to_s
               else
                  fmt[:filled] = ''
               end

               sum += fmt[:filled].size
            end

            format.each { |fmt| fmt[:sum] = sum }
            format
         end

         def draw
            @win.erase
            draw_position_and_length
            
            if @track
               fill(Config[:'playinginfo.format1']).each_with_index do |fmt,i|
                  @win.center(fmt[:sum]) if i == 0
                  @win.with_attr(UI::Colors.set(nil, *fmt[:curses_attrs])) do
                     @win << fmt[:filled]
                  end
               end

               @win.with_attr(Theme[:'playinginfo.state']) do
                  @win.from_right(@state.to_s.size + 2) << "[#{@state}]"
               end

               @win.next_line

               fill(Config[:'playinginfo.format2']).each_with_index do |fmt,i|
                  @win.center(fmt[:sum]) if i == 0
                  @win.with_attr(UI::Colors.set(nil, *fmt[:curses_attrs])) do
                     @win << fmt[:filled]
                  end
               end
            else
               @win.center_string(STOPPED_HEADING)
               @win.with_attr(Theme[:'playinginfo.state']) do
                  @win.from_right(9) << '[stopped]'
               end
            end

            #@win.next_line.addstr('─' * @size.width)
         end
      end
   end
end

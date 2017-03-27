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
            with_lock { @state = :stopped; @position = 0; want_redraw }
         end

         def track=(t)
            return if @track == t
            with_lock { @track = t; want_redraw }
         end

         def draw_position_and_length
            return unless visible?
            @win.attrset(Theme[:'playinginfo.position'])
            @win.mvaddstr(0, 0, "[#{Common::to_time(@position)}/#{Common::to_time(@length)}]")
            noutrefresh
         end

         def attach(playlist, player)
            player.events.on(:pause)  { self.paused!  }
            player.events.on(:stop)   { self.stopped! }
            player.events.on(:play)   { self.playing! }

            player.events.on(:position_change) do
               old_pos, old_length = @position, @length
               @position = player.position.to_i
               @length = player.length.to_i
               return if old_pos == @position and old_length == @length
               draw_position_and_length
            end

            playlist.events.on(:current_changed) {
               self.track=(playlist[playlist.current_playing])
            }

            # TODO: move mouse?
            self.mouse.on(ICurses::BUTTON1_CLICKED) do |mevent|
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
                  @win.attrset(UI::Colors.set(nil, *fmt[:curses_attrs]))
                  @win << fmt[:filled]
               end

               @win.attrset(Theme[:'playinginfo.state'])
               @win.from_right(@state.to_s.size + 2) << "[#{@state}]"

               @win.next_line

               fill(Config[:'playinginfo.format2']).each_with_index do |fmt,i|
                  @win.center(fmt[:sum]) if i == 0
                  @win.attrset(UI::Colors.set(nil, *fmt[:curses_attrs]))
                  @win << fmt[:filled]
               end
            else
               @win.attrset(0)
               @win.center_string(STOPPED_HEADING)
               @win.attrset(Theme[:'playinginfo.state'])
               @win.from_right(9) << '[stopped]'
            end

            #@win.next_line.addstr('~' * @size.width)
         end
      end
   end
end

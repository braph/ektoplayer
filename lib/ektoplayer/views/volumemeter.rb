require_relative '../ui/widgets'
require_relative '../config'
require_relative '../theme'

module Ektoplayer
   module Views
      class VolumeMeter < UI::Window
         def layout
            super
            load_colors(true)
         end

         def load_colors(force=false)
            return if @fade and not force

            if Theme.current == 256
               fader = UI::ColorFader.new([25,26,27,32,39,38,44,44,45,51,87,159,195])
            elsif Theme.current == 8
               fader = UI::ColorFader.new([:blue])
            else
               fader = UI::ColorFader.new([-1])
            end

            @fade = fader.fade(@size.width)
            @level_width = @size.width
            @level_char = Config[:'volumemeter.level_char']
            @rest_char  = Config[:'volumemeter.rest_char']
         end

         def level=(level)
            return unless visible?

            new_level_width = (1.4 * level * @size.width).to_i.clamp(0, @size.width - 1) rescue 0
            return if @level_width == new_level_width
            load_colors

            if new_level_width > @level_width
               @win.setpos(0, @level_width)
               (@level_width).upto(new_level_width).each do |i|
                  @win.attron(@fade[i])
                  @win << @level_char
               end
            else
               @win.setpos(0, new_level_width)
            end

            if (repeat = @size.width - @win.curx - 1) > 0
               @win.attron(Theme[:'volumemeter.rest'])
               @win << @rest_char * (repeat + 1)
            end

            @level_width = new_level_width 
            @win.refresh
         end

         def attach(player)
            player.events.on(:position_change) { self.level=(player.level) }
            player.events.on(:stop)            { self.level=(90)           }
            player.events.on(:pause)           { self.level=(90)           }
         end
         
         def draw
            load_colors
            @win.setpos(0,0)

            @level_width.times do |i|
               @win.attron(@fade[i])
               @win << @level_char
            end

            @win.attron(Theme[:'volumemeter.rest'])
            @win << @rest_char * (@size.width - @win.curx)
         end
      end
   end
end

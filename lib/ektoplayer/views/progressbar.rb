require_relative '../ui/widgets'
require_relative '../config'
require_relative '../theme'

module Ektoplayer
   module Views
      class ProgressBar < UI::Window
         def attach(player)
            player.events.on(:position_change) do
               self.percent_playing = player.position_percent
            end

            view=self # TODO
            [ICurses::BUTTON1_CLICKED, ICurses::BUTTON2_CLICKED, ICurses::BUTTON3_CLICKED].
               each do |button|
               view.mouse.on(button) do |mevent|
                  pos = Float(mevent.x) / (self.size.width - 1) * player.length rescue player.position
                  player.seek(pos.to_i)
               end
            end
         end

         def percent_playing=(percent_playing)
            char_width = (percent_playing * @size.width).to_i
            return if char_width == @progress_width

            with_lock do
               @progress_width = char_width
               want_redraw
            end
         end

         def draw
            @win.move(0,0)
            @progress_width ||= 0
            @progress_char  ||= Config[:'progressbar.progress_char']
            @rest_char      ||= Config[:'progressbar.rest_char']

            @win.attrset(Theme[:'progressbar.progress'])
            repeat = (@progress_width - @progress_char.size)
            @win << @progress_char[0] * repeat if repeat > 0
            @win << @progress_char[1..-1] if @progress_width > 0

            @win.attrset(Theme[:'progressbar.rest'])
            @win << @rest_char * (@size.width - @win.curx)
         end
      end
   end
end

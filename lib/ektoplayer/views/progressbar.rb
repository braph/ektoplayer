require_relative '../ui/widgets'
require_relative '../config'
require_relative '../theme'

module Ektoplayer
   module Views
      class ProgressBar < UI::Window
         def layout
            super
            load_colors
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
            @progress_width = @size.width
            @progress_char = Config[:'progressbar.progress_char']
            @rest_char= Config[:'progressbar.rest_char']
         end

         def attach(player)
            player.events.on(:position_change) do
               old = @progress_width
               @progress_width = (player.position_percent * @size.width).to_i rescue @size.width

               if (old != @progress_width) and visible?
                  draw
                  noutrefresh
               end
            end

            view=self # TODO
            [ICurses::BUTTON1_CLICKED, ICurses::BUTTON2_CLICKED, ICurses::BUTTON3_CLICKED].
               each do |button|
               view.mouse.on(button) do |mevent|
                  pos = Float(mevent.x) / (self.size.width - 1) * player.length rescue player.position
                  player.seek(pos.to_i)
                  @progress_width = mevent.x
                  draw
                  noutrefresh
               end
            end
         end

         def draw
            load_colors
            @win.move(0,0)

            @progress_width.times do |i|
               @win.attron(@fade[i])
               @win.addstr(@progress_char)
            end

            @win.attron(Theme[:'progressbar.rest'])
            @win << @rest_char * (@size.width - @win.curx)
         end
      end
   end
end

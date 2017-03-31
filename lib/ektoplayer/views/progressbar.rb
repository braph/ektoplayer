require_relative '../ui/widgets'
require_relative '../config'
require_relative '../theme'

module Ektoplayer
   module Views
      class ProgressBar < UI::Pad
         def layout
            super
            self.pad_size=(UI::Size.new(
               height: 1, width:  @size.width * 2
            ))

            if Theme.current == 256
               fader = UI::ColorFader.new([25,26,27,32,39,38,44,44,45,51,87,159,195])
            elsif Theme.current == 8
               fader = UI::ColorFader.new([:blue])
            else
               fader = UI::ColorFader.new([-1])
            end

            progress_char = Config[:'progressbar.progress_char']

            @win.move(0,0)

            fader.fade(@size.width).each do |c|
               @win.attron(c)
               @win.addstr(progress_char)
            end

            @win.attron(Theme[:'progressbar.rest'])
            @win << Config[:'progressbar.rest_char'] * @size.width
         end

         def attach(player)
            player.events.on(:position_change) do
               old = @progress_width
               @progress_width = @size.width - (player.position_percent * @size.width).to_i rescue 0

               if (old != @progress_width) and visible?
                  @pad_mincol = (@progress_width)
                  refresh
               end
            end

            view=self # TODO
            [ICurses::BUTTON1_CLICKED, ICurses::BUTTON2_CLICKED, ICurses::BUTTON3_CLICKED].
               each do |button|
               view.mouse.on(button) do |mevent|
                  x = mevent.x - @pad_mincol
                  pos = Float(x) / (self.size.width - 1) * player.length rescue player.position
                  player.seek(pos.to_i)
                  @progress_width = x
                  self.pad_mincol=(@size.width - @progress_width)
               end
            end
         end

         def draw
         end
      end
   end
end

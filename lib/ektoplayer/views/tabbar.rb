require_relative '../ui/widgets'
require_relative '../theme'

module Ektoplayer
   module Views
      class TabBar < UI::Pad
         def initialize(**opts)
            super(**opts)
            events.register(:tab_clicked)
            @selected, @tabs = 0, []
         end

         def add(title)
            with_lock do
               @tabs << title
               want_redraw
            end
         end

         def selected=(index)
            index = index.clamp(0, @tabs.size - 1)
            return if index == @selected

            with_lock do
               @selected = index
               want_redraw
            end
         end

         def draw
            self.pad_size=(@size.update(height: 1))
            mouse_section.clear
            @win.erase
            @win.move(0,0)

            @tabs.each_with_index do |title, i|
               mevent = with_mouse_section_event do
                  if i == @selected
                     @win.attrset(Theme[:'tabbar.selected'])
                  else
                     @win.attrset(Theme[:'tabbar.unselected'])
                  end

                  @win << title.to_s
                  @win.addch(32) # ' '
               end
               mevent.on(ICurses::BUTTON1_CLICKED) do
                  trigger(@events, :tab_clicked, i)
               end
            end
         end
      end
   end
end

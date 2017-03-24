require_relative '../icurses'

require_relative 'controller'

module Ektoplayer
   module Controllers
      class Browser < Controller
         def initialize(view, browser, view_operations, operations)
            super(view)
            view.attach(browser)

            register = view_operations.with_register('browser.')

            %w(up down page_up page_down top bottom
               search_up search_down search_next search_prev toggle_selection).
               each { |op| register.(op, &view.method(op)) }

            register.(:enter) do
               operations.send(:'browser.enter', view.selected)
            end

            register.(:add_to_playlist) do
               #if tracks = browser.tracks(view.selected)
               view.get_selection.each do |index|
                  operations.send(:'browser.add_to_playlist', index)
               end
               #end
            end

            # TODO: mouse?
            view.mouse.on(65536) do view.up(5) end
            view.mouse.on(2097152) do view.down(5) end

            [ICurses::BUTTON1_DOUBLE_CLICKED, ICurses::BUTTON3_CLICKED].each do |btn|
               view.mouse.on(btn) do |mevent|
                  view.select_from_cursorpos(mevent.y)
                  view_operations.send(:'browser.enter')
               end
            end

            [ICurses::BUTTON1_CLICKED, ICurses::BUTTON2_CLICKED].
               each do |button|
               view.mouse.on(button) do |mevent|
                  view.select_from_cursorpos(mevent.y)
               end
            end
         end
      end
   end
end


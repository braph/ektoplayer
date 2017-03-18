require 'curses'

require_relative 'controller'

module Ektoplayer
   module Controllers
      class Browser < Controller
         def initialize(view, browser, view_operations, operations)
            super(view)
            view.attach(browser)

            register = view_operations.with_register('browser.')

            %w(up down page_up page_down top bottom
               search_up search_down search_next search_prev).
               each { |op| register.(op, &view.method(op)) }

            register.(:enter) do
               operations.send(:'browser.enter', view.selected)
            end

            register.(:add_to_playlist) do
               #if tracks = browser.tracks(view.selected)
               operations.send(:'browser.add_to_playlist', view.selected)
               #end
            end

            # TODO: mouse?
            view.mouse.on(65536) do view.scroll_up(3) end
            view.mouse.on(2097152) do view.scroll_down(3) end

            view.mouse.on(Curses::BUTTON1_DOUBLE_CLICKED) do |mevent|
               view.select_from_cursorpos(mevent.y)
               view_operations.send(:'browser.enter')
            end

            [Curses::BUTTON1_CLICKED, Curses::BUTTON2_CLICKED, Curses::BUTTON3_CLICKED].
               each do |button|
               view.mouse.on(button) do |mevent|
                  view.select_from_cursorpos(mevent.y)
               end
            end
         end
      end
   end
end


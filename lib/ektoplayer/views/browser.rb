require_relative '../ui/widgets'
require_relative '../config'

module Ektoplayer
   module Views
      class Browser < UI::ListWidget
         def initialize(**opts)
            super(**opts)
            if ICurses.colors == 256
               f = Config[:'playlist.format_256']
            else
               f = Config[:'playlist.format']
            end

            self.item_renderer=(TrackRenderer.new(width: @size.width, format: f))
         end

         def attach(browser)
            @browser = browser
            browser.events.on(:changed, &self.method(:reload))
            reload
         end

         private def reload
            fail unless @browser
            self.list=(@browser.current.map.to_a)
         end
      end
   end
end

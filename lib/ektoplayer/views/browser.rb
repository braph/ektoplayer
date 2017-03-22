require_relative '../ui/widgets'
require_relative '../config'

module Ektoplayer
   module Views
      class Browser < UI::ListWidget
         def initialize(**opts)
            super(**opts)
            self.item_renderer=(TrackRenderer.new(
               width: @size.width, format: Config[:'browser.format']))
         end

         def attach(browser)
            @browser = browser
            browser.events.on(:changed, &self.method(:reload))
            reload
         end

         private def reload
            fail unless @browser
            #puts 'eeheheheh reload!' todo refresh?
            self.list=(@browser.current.map.to_a)
         end
      end
   end
end

require_relative '../icurses'

require_relative 'controller'

module Ektoplayer
   module Controllers
      class Help < Controller
         def initialize(view, view_operations)
            super(view)
            register = view_operations.with_register('help.')
            %w(up down page_up page_down top bottom).
               each { |op| register.(op, &view.method(op)) }

            # TODO: mouse?
            view.mouse.on(65536)   { view.page_up   }
            view.mouse.on(2097152) { view.page_down }
         end
      end
   end
end


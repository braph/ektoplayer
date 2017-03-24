require_relative '../icurses'

require_relative 'controller'

module Ektoplayer
   module Controllers
      class Info < Controller
         def initialize(view, player, playlist, trackloader, database, view_operations)
            super(view)
            view.attach(player, playlist, trackloader, database)
            register = view_operations.with_register('info.')
            %w(up down page_up page_down top bottom).
               each { |op| register.(op, &view.method(op)) }

            # TODO: mouse?
            view.mouse.on(65536)   { view.page_up   }
            view.mouse.on(2097152) { view.page_down }
         end
      end
   end
end


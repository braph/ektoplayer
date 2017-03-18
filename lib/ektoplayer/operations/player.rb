module Ektoplayer
   module Operations
      class Player
         def initialize(operations, player)
            register = operations.with_register('player.')
            %w(play stop pause toggle forward backward).
               each { |op| register.(op, &player.method(op)) }
         end
      end
   end
end

module Ektoplayer
   module Operations
      # Available operations for +Models::Player+:
      # +play+::     see
      # +stop+::     see
      # +pause+::    see
      # +toggle+::   see
      # +forward+::  see
      # +backward+:: see
      class Player
         def initialize(operations, player)
            register = operations.with_register('player.')
            register.(:play,       &player.method(:play))
            register.(:stop,       &player.method(:stop))
            register.(:pause,      &player.method(:pause))
            register.(:toggle,     &player.method(:toggle))
            register.(:forward,    &player.method(:forward))
            register.(:backward,   &player.method(:backward))
         end
      end
   end
end

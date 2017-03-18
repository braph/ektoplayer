require_relative '../events'

module Ektoplayer
   module Models
      # Base class for all other models.
      class Model
         attr_reader :events

         def initialize
            @events = Events.new
            @events.no_auto_create
         end
      end
   end
end

require_relative 'model'
require_relative '../players/mpg_wrapper_player'

module Ektoplayer
   module Models
      class Player < Model
         def initialize(client)
            super()
            @client = client
            @player = MpgWrapperPlayer.new
            @events = @player.events
            #@events.register(:position_change, :track_completed, :pause, :stop, :play)
            #@player.events.on_all(&@events.method(:trigger))

            %w(pause toggle stop forward backward seek
            length position position_percent can_http?).each do |m|
               self.define_singleton_method(m, &@player.method(m))
            end
         end

         def play(file)
            Application.log(self, 'playing', file)
            @player.play(file) rescue Application.log(self, $!)
         end
      end
   end
end

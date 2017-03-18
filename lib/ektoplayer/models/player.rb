require_relative 'model'
require_relative '../mp3player'

module Ektoplayer
   module Models
      class Player < Model
         def initialize(client)
            super()
            @client = client
            @player = Mp3Player.new
            @events.register(:position_change, :track_completed, :pause, :stop, :play)
            @player.events.on_all(&@events.method(:trigger))

            %w(pause toggle stop forward backward seek
            length position position_percent level).each do |m|
               self.define_singleton_method(m, &@player.method(m))
            end
         end

         def play(file)
            Application.log(self.class, 'playing', file)
            @player.play(file)
         rescue => e
            Application.log(e)
         end

         def close;  @player.close  end
      end
   end
end

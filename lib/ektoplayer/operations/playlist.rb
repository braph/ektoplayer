module Ektoplayer
   module Operations
      class Playlist
         def initialize(operations, playlist, player, trackloader)
            @playlist, @player, @trackloader = playlist, player, trackloader
            register = operations.with_register('playlist.')

            register.(:clear,   &@playlist.method(:clear))
            register.(:delete,  &@playlist.method(:delete))

            %w(play reload play_next play_prev download_album).each do |operation|
               register.(operation, &self.method(operation))
            end
         end

         def download_album(index)
            return unless track = @playlist[index]
            Thread.new do
               @trackloader.download_album(track['url']) rescue (
                  Application.log(self, $!)
               )
            end.join(0.3) # prevent too many hits
         end

         def reload(index)
            return unless track = @playlist[index]
            Thread.new do
               @trackloader.get_track_file(track['url'], reload: true) rescue (
                  Application.log(self, $!)
               )
            end.join(0.3) # prevent too many hits
         end

         def play(index)
            return unless track = @playlist[index]
            @playlist.current_playing=(index)
            Thread.new do
               @player.play(@trackloader.get_track_file(track['url']))
            end.join(0.3) # prevent too many hits
         end

         def play_next
            return if @playlist.empty? or !@playlist.current_playing 
            index = (@playlist.current_playing + 1) % @playlist.size
            play(index)
         end

         def play_prev
            return if @playlist.empty? or !@playlist.current_playing 

            if @playlist.current_playing == 0
               play(@playlist.size - 1)
            else
               play(@playlist.current_playing - 1)
            end
         end

         private def get_next_pos
            return unless index = @playlist.current_playing

            if @playlist.repeat_mode == :track
               return index
            elsif index + 1 >= @playlist.size
               return 0 if @playlist.repeat_mode == :playlist
            else
               return index  + 1
            end
         end
      end
   end
end

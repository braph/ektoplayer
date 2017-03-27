module Ektoplayer
   module Operations
      class Browser
         # Operations for +Model::Browser+:
         # +enter+::             see
         # +back+::              see
         # +add_to_playlist+::   see
         def initialize(operations, browser, playlist)
            register = operations.with_register('browser.')
            register.(:back,   &browser.method(:back))

            register.(:enter) do |index|
               unless browser.enter(index)
                  tracks = browser.tracks(index)
                  playlist.add(*tracks)
                  operations.send(:'playlist.play', playlist.size - tracks.size)
               end
            end
                  
            register.(:add_to_playlist) do |index|
               tracks = browser.tracks(index)
               playlist.add(*tracks)
            end
         end
      end
   end
end

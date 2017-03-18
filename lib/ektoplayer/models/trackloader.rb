require_relative 'model'

module Ektoplayer
   module Models
      class Trackloader < Model
         def initialize(client)
            super()
            @trackloader = client.trackloader

            %w(get_track_file download_album downloads
            ).each do |m|
               self.define_singleton_method(m, &@trackloader.method(m))
            end
         end
      end
   end
end

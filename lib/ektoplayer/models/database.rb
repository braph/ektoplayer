require_relative 'model'
require_relative '../updater'

module Ektoplayer
   module Models
      # This model represents the state of the database.
      # Events:
      # _changed_:: the database has been modified
      # _update_started_:: database update has been started
      # _update_finished_:: database update has been finished
      
      class Database < Model
         attr_reader :events

         def initialize(client)
            super()
            @client = client
            @client.database.events.on(:changed) { @events.trigger(:changed) }
            @events.register(:update_started, :changed, :update_finished)
         end

         def track_count; @client.database.track_count  end
         def album_count; @client.database.album_count  end

         def get_description(*a)
            @client.database.get_description(*a)
         end
       
         def updating?
            @update_thread and @update_thread.alive?
         end
        
         def stop!
            @update_thread and @update_thread.kill
            @update_thread = nil
         end
         
         def update(**opts)
            unless updating?
               db_updater = DatabaseUpdater.new(@client.database)
               @update_thread = Thread.new do
                  @events.trigger(:update_started)
                  db_updater.update(**opts)
                  @events.trigger(:update_finished)
               end
            else
               Application.log(self, 'already updating')
            end
         end
      end
   end
end


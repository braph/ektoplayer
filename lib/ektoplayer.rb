require_relative 'ektoplayer/application'

module Ektoplayer 
   class Ektoplayer
      def Ektoplayer.start
         app = Application.new
         app.run
      end
   end
end

require 'fileutils'

require_relative 'database'
require_relative 'trackloader'

module Ektoplayer
   class Client
      attr_reader :database
      attr_reader :trackloader

      def initialize
         db_file = Config.get(:database_file)
         FileUtils::touch(db_file) unless File.file? db_file
         @database = Database.new(db_file)
         @trackloader = Trackloader.new(@database)
      end
   end
end

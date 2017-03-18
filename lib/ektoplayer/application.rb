require 'fileutils'
require 'date'

{  '.'            => %w(config theme bindings client common ui),
   'views'        => %w(mainwindow),
   'models'       => %w(player browser playlist database trackloader),
   'operations'   => %w(operations player browser playlist),
   'controllers'  => %w(mainwindow browser playlist info help)
}.each { |d,files| files.each { |f| require_relative "#{d}/#{f}" } }

module Ektoplayer
   class Application
      VERSION = '0.1'.freeze
      GITHUB_URL = 'https://github.com/braph/ektoplayer'.freeze
      EKTOPLAZM_URL = 'http://www.ektoplazm.com'.freeze

      CONFIG_DIR  = File.join(Dir.home, '.config', 'ektoplayer').freeze
      CONFIG_FILE = File.join(CONFIG_DIR, 'ektoplayer.rc').freeze

      def self.log(*msg)
         $stderr.write("#{DateTime.now.rfc3339}: #{msg.join(' ')}\n")
         $stderr.flush
      end

      def self.open_log(file)
         $stderr.reopen(file, ?a)
         $stderr.sync=(true)
      end

      def run
         #Thread.abort_on_exception=(true)

         # make each configuration object globally accessible as a singleton
         [Config, Bindings, Theme].each { |c| Common::mksingleton(c) }

         if File.file? Config::CONFIG_FILE
            begin Config.parse(Config::CONFIG_FILE, Bindings, Theme)
            rescue => e
               fail "Config: #{e}"
            end
         end

         begin FileUtils::mkdir_p Config::CONFIG_DIR
         rescue => e
            fail "Could not create config dir: #{e}"
         end

         Application.open_log(Config[:log_file])

         if Config[:use_cache]
            unless File.directory? Config[:cache_dir]
               begin FileUtils::mkdir Config[:cache_dir]
               rescue => e
                  fail "Could not create cache dir: #{e}"
               end
            end
         end

         [:temp_dir, :download_dir, :archive_dir].each do |key|
            unless File.directory? Config[key]
               begin FileUtils::mkdir Config[key]
               rescue => e
                  fail "Could not create #{key}: #{e}"
               end
            end
         end

         UI::Canvas.run do
            if Config[:use_colors] == :auto
               Theme.use_colors(ENV['TERM'] =~ /256/ ? 256 : 8)
            else
               Theme.use_colors(Config[:use_colors])
            end

            @client = Client.new

            # ... models ...
            @player      = Models::Player.new(@client)
            @browser     = Models::Browser.new(@client)
            @playlist    = Models::Playlist.new
            @database    = Models::Database.new(@client)
            @trackloader = Models::Trackloader.new(@client)

            # ... operations ...
            @operations = Operations::Operations.new
            @view_operations = Operations::Operations.new
            @operations.register(:quit,    &method(:exit))
            @operations.register(:reload,  &@browser.method(:reload))
            @operations.register(:update,  &@database.method(:update))
            @operations.register(:refresh) { UI::Canvas.on_winch; UI::Canvas.update_screen(true) }
            Operations::Player.new(@operations, @player)
            Operations::Browser.new(@operations, @browser, @playlist)
            Operations::Playlist.new(@operations, @playlist, @player, @trackloader)

            # ... views ...
            @mainwindow = UI::Canvas.sub(Views::MainWindow)

            # next operations may take some time, espacially the ones
            # using the database (@browser), so we put this inside a thread
            Thread.new do
               # ... controllers ...
               Controllers::MainWindow.new(@mainwindow, @view_operations)
               Controllers::Browser.new(@mainwindow.browser, @browser, @view_operations, @operations)
               Controllers::Playlist.new(@mainwindow.playlist, @playlist, @view_operations, @operations)
               Controllers::Help.new(@mainwindow.help, @view_operations)
               Controllers::Info.new(@mainwindow.info, @playlist, @trackloader, @database, @view_operations)
               @mainwindow.progressbar.attach(@player)
               @mainwindow.volumemeter.attach(@player)
               @mainwindow.playinginfo.attach(@playlist, @player)

               # ... events ...
               @database.events.on(:update_finished, &@browser.method(:reload ))
               @player.events.on(:stop) do |reason|
                  @operations.send(:'playlist.play_next') if reason == :track_completed
               end

               # ... bindings ...
               Bindings.bind_view(:global, @mainwindow, @view_operations, @operations)
               %w(splash playlist browser info help).each do |w|
                  Bindings.bind_view(w, @mainwindow.send(w), @view_operations, @operations)
               end

               @player.stop

               # If database is empty, start an initial update
               if @browser.tracks(0).size < 1
                  @operations.send(:update)
               elsif (c = Config[:small_update_pages]) > 0
                  @operations.send(:update, pages: c)
               end

               if (n = Config[:playlist_load_newest]) > 0
                  r = @client.database.select(order_by: 'date', limit: n)
                  @playlist.add(*r)
               end
            end

            UI::Canvas.update_screen
            UI::Input.start_loop
         end
      rescue => e
         puts "Error: #{e}"
         Application.log("#{e}\n", e.backtrace.join(?\n))
      end
   end
end

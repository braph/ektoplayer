require 'fileutils'
require 'date'

{  '.'            => %w(compat config theme bindings client common ui),
   'views'        => %w(mainwindow),
   'models'       => %w(player browser playlist database trackloader),
   'operations'   => %w(operations player browser playlist),
   'controllers'  => %w(mainwindow browser playlist info help)
}.each { |d,files| files.each { |f| require_relative "#{d}/#{f}" } }

module Ektoplayer
   class Application
      VERSION = '0.1.4'.freeze
      GITHUB_URL = 'https://github.com/braph/ektoplayer'.freeze
      EKTOPLAZM_URL = 'http://www.ektoplazm.com'.freeze

      CONFIG_DIR  = File.join(Dir.home, '.config', 'ektoplayer').freeze
      CONFIG_FILE = File.join(CONFIG_DIR, 'ektoplayer.rc').freeze

      def self.log(from, *msgs)
         func = caller[0][/`.*'/][1..-2]
         from = from.class unless from.is_a?String
         $stderr.puts("#{DateTime.now.rfc3339} #{from}.#{func}: " + msgs.join(' '))

         if e = msgs.select { |m| m.kind_of?Exception }[0] 
            $stderr.puts "#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.join(?\n)
         end
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
            Config.parse(Config::CONFIG_FILE, Bindings, Theme) rescue (
               fail "Config: #{$!}"
            )
         end

         FileUtils::mkdir_p Config::CONFIG_DIR rescue (
            fail "Could not create config dir: #{$!}"
         )

         Application.open_log(Config[:log_file])

         if Config[:use_cache]
            unless File.directory? Config[:cache_dir]
               FileUtils::mkdir Config[:cache_dir] rescue (
                  fail "Could not create cache dir: #{$!}"
               )
            end
         end

         [:temp_dir, :download_dir, :archive_dir].each do |key|
            unless File.directory? Config[key]
               FileUtils::mkdir Config[key] rescue (
                  fail "Could not create #{key}: #{$!}"
               )
            end
         end

         UI::Canvas.run do
            if Config[:use_colors] == :auto
               Theme.use_colors(ENV['TERM'] =~ /256/ ? 256 : 8)
            else
               Theme.use_colors(Config[:use_colors])
            end

            client = Client.new

            # ... models ...
            player      = Models::Player.new(client)
            browser     = Models::Browser.new(client)
            playlist    = Models::Playlist.new
            database    = Models::Database.new(client)
            trackloader = Models::Trackloader.new(client)

            # ... operations ...
            operations = Operations::Operations.new
            operations.register(:quit,    &method(:exit))
            operations.register(:reload,  &browser.method(:reload))
            operations.register(:update,  &database.method(:update))
            operations.register(:refresh) { UI::Canvas.on_winch; UI::Canvas.update_screen(true) }
            Operations::Player.new(operations, player)
            Operations::Browser.new(operations, browser, playlist)
            Operations::Playlist.new(operations, playlist, player, trackloader)

            # ... views ...
            main_w = UI::Canvas.sub(Views::MainWindow)

            # next operations may take some time, espacially the ones
            # using the database (browser), so we put this inside a thread
            Thread.new do
               begin

               # ... controllers ...
               view_ops = Operations::Operations.new
               Controllers::MainWindow.new(main_w, view_ops)
               Controllers::Browser.new(main_w.browser, browser, view_ops, operations)
               Controllers::Playlist.new(main_w.playlist, playlist, view_ops, operations)
               Controllers::Help.new(main_w.help, view_ops)
               Controllers::Info.new(main_w.info, player, playlist, trackloader, database, view_ops)
               main_w.progressbar.attach(player)
               main_w.volumemeter.attach(player)
               main_w.playinginfo.attach(playlist, player)

               # ... events ...
               database.events.on(:update_finished, &browser.method(:reload ))
               player.events.on(:stop) do |reason|
                  operations.send(:'playlist.play_next') if reason == :track_completed
               end

               # ... bindings ...
               Bindings.bind_view(:global, main_w, view_ops, operations)
               %w(splash playlist browser info help).each do |w|
                  Bindings.bind_view(w, main_w.send(w), view_ops, operations)
               end

               player.stop

               # If database is empty, start an initial update
               if browser.tracks(0).size < 1
                  operations.send(:update)
               elsif (c = Config[:small_update_pages]) > 0
                  operations.send(:update, pages: c)
               end

               if (n = Config[:playlist_load_newest]) > 0
                  r = client.database.select(order_by: 'date', limit: n)
                  playlist.add(*r)
               end

               rescue
                  Application.log(self, $!)
               end
            end

            UI::Canvas.update_screen
            UI::Input.start_loop
         end
      rescue
         puts "Error: #{$!}"
         Application.log(self, $!)
      end
   end
end

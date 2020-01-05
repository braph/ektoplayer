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
      VERSION       = '0.1.24'.freeze
      GITHUB_URL    = 'https://github.com/braph/ektoplayer'.freeze
      EKTOPLAZM_URL = 'https://ektoplazm.com'.freeze

      EKTOPLAZM_ALBUM_BASE_URL   = "#{EKTOPLAZM_URL}/free-music".freeze
      EKTOPLAZM_COVER_BASE_URL   = "#{EKTOPLAZM_URL}/img".freeze
      EKTOPLAZM_TRACK_BASE_URL   = "#{EKTOPLAZM_URL}/audio".freeze
      EKTOPLAZM_STYLE_BASE_URL   = "#{EKTOPLAZM_URL}/style".freeze
      EKTOPLAZM_ARCHIVE_BASE_URL = "#{EKTOPLAZM_URL}/files".freeze

      def self.album_url(album)
         "#{EKTOPLAZM_ALBUM_BASE_URL}/#{album}"
      end

      def self.cover_url(cover)
         "#{EKTOPLAZM_COVER_BASE_URL}/#{cover}"
      end

      def self.track_url(track)
         "#{EKTOPLAZM_TRACK_BASE_URL}/#{track}"
      end

      def self.style_url(style)
         "#{EKTOPLAZM_STYLE_BASE_URL}/#{style}"
      end

      def self.archive_url(archive)
         "#{EKTOPLAZM_ARCHIVE_BASE_URL}/#{archive}"
      end

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
         puts "\033]0;ektoplayer\007"
         Process.setproctitle('ektoplayer')
         Thread.report_on_exception=(true) if Thread.respond_to? :report_on_exception

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
            Application.log(self, "using '#{$USING_CURSES}' with #{ICurses.colors} colors available")

            if Config[:use_colors] == :auto
               Theme.use_colors(ICurses.colors >= 256 ? 256 : 8)
            else
               Theme.use_colors(Config[:use_colors])
            end

            client = Client.new

            # ... models ...
            player      = Models::Player.new(client, Config[:audio_system])
            browser     = Models::Browser.new(client)
            playlist    = Models::Playlist.new
            database    = Models::Database.new(client)
            trackloader = Models::Trackloader.new(client)

            # ... operations ...
            operations = Operations::Operations.new
            operations.register(:quit) do
               Thread.list.each { |t| t.kill if t != Thread.current }
               FileUtils.rm(Dir.glob(File.join(Config[:temp_dir], '~ekto-*'))) rescue nil
               raise SystemExit
            end

            operations.register(:reload,  &browser.method(:reload))
            operations.register(:update,  &database.method(:update))
            operations.register(:refresh) { UI::Canvas.update_screen(true, true) }
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
               main_w.playinginfo.attach(playlist, player)

               # ... events ...
               database.events.on(:update_finished, &browser.method(:reload))
               player.events.on(:stop) do |reason|
                  operations.send(:'playlist.play_next') if reason == :track_completed
               end
               
               # ... bindings ...
               Bindings.bind_view(:global, main_w, view_ops, operations)
               %w(splash playlist browser info help).each do |w|
                  Bindings.bind_view(w, main_w.send(w), view_ops, operations)
               end

               player.stop

               # Preload playlist
               if (n = Config[:playlist_load_newest]) > 0
                  r = client.database.select(
                     order_by: 'date DESC,album,number',
                     limit: n
                  )
                  playlist.add(*r)
               end

               # If database is empty, start an initial update
               if browser.tracks(0).size < 1
                  operations.send(:update)
               elsif (c = Config[:small_update_pages]) > 0
                  operations.send(:update, pages: c)
               end

               if Config[:prefetch]
                  Thread.new do
                     current_download_track = nil

                     loop do
                        sleep 5

                        next_track = playlist.get_next_pos
                        next if current_download_track == next_track

                        if player.length > 30 and player.position_percent > 0.5
                           trackloader.get_track_file(playlist[next_track]['url'])
                           current_download_track = next_track
                           sleep 5
                        end
                     end
                  end
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

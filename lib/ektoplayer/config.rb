require 'shellwords'
require 'nokogiri'

module Ektoplayer
   class ColumnFormat
      def self.parse_column_format(format)
         self.parse_simple_format(format).
            select { |f| f[:tag] != 'text' }.
            map do |fmt|
            fmt[:size]    = fmt[:size].to_i      if fmt[:size]
            fmt[:rel]     = fmt[:rel].to_i       if fmt[:rel]
            fmt[:justify] = fmt[:justify].to_sym if fmt[:justify]

            begin
               fail 'Missing size= or rel=' if (!fmt[:size] and !fmt[:rel])
               fail 'size= and rel= are mutually exclusive' if (fmt[:size] and fmt[:rel])
            rescue 
               fail "column: #{fmt[:tag]}: #{$!}"
            end

            fmt
         end
      end

      def self.parse_simple_format(format)
         self._parse_markup(format).map do |fmt|
            fmt[:curses_attrs] = [
               (fmt[:fg] and Integer(fmt[:fg]) rescue fmt[:fg].to_sym),
               (fmt[:bg] and Integer(fmt[:bg]) rescue fmt[:bg].to_sym),
            ]
            fmt[:curses_attrs] << :bold      if fmt[:bold]
            fmt[:curses_attrs] << :blink     if fmt[:blink]
            fmt[:curses_attrs] << :standout  if fmt[:standout]
            fmt[:curses_attrs] << :underline if fmt[:underline]
            fmt
         end
      end

      def self._parse_markup(format)
         Nokogiri::XML("<f>#{format}</f>").first_element_child.
            children.map do |fmt|
               fmt1 = fmt.attributes.map do |name,a|
                  [name.to_sym, a.value]
               end.to_h.update(tag: fmt.name)
               fmt1[:text] = fmt.text if fmt1[:tag] == 'text'
               fmt1
         end
      end
   end

   class Config
      CONFIG_DIR  = File.join(Dir.home, '.config', 'ektoplayer').freeze
      CONFIG_FILE = File.join(CONFIG_DIR, 'ektoplayer.rc').freeze

      DEFAULT_PLAYLIST_FORMAT = %{\
         <number size="3" fg="magenta" />\
         <artist rel="25" fg="blue"    />\
         <album  rel="30" fg="red"     />\
         <title  rel="33" fg="yellow"  />\
         <styles rel="20" fg="cyan"    />\
         <bpm    size="3" fg="green" justify="right" />}.squeeze(' ').freeze

      DEFAULT_PLAYINGINFO_FORMAT_TOP =
         '<text fg="black">&lt;&lt; </text><title bold="on" fg="yellow" /><text fg="black"> &gt;&gt;</text>'.freeze

      DEFAULT_PLAYINGINFO_FORMAT_BOTTOM = 
         '<artist bold="on" fg="blue" /><text> - </text><album bold="on" fg="red" /><text> (</text><year fg="cyan" /><text>)</text>'.freeze

      DEFAULT_PLAYLIST_FORMAT_256 = %{\
         <number size="3" fg="97"  />\
         <artist rel="25" fg="24"  />\
         <album  rel="30" fg="160" />\
         <title  rel="33" fg="178" />\
         <styles rel="20" fg="37"  />\
         <bpm    size="3" fg="28" justify="right" />}.squeeze(' ').freeze

      DEFAULT_PLAYINGINFO_FORMAT_TOP_256 =
         '<text fg="236">&lt;&lt; </text><title bold="on" fg="178" /><text fg="236"> &gt;&gt;</text>'.freeze

      DEFAULT_PLAYINGINFO_FORMAT_BOTTOM_256 = 
         '<artist bold="on" fg="24" /><text> - </text><album bold="on" fg="160" /><text> (</text><year fg="37" /><text>)</text>'.freeze

      def register(key, description, default, method=nil)
         # parameter `description` is used by tools/mkconfig.rb, but not here

         if method
            @cast[key.to_sym]    = method
            @options[key.to_sym] = method.(default).freeze
         else
            @options[key.to_sym] = default.freeze
         end
      end
      alias :reg :register

      def initialize
         @options = Hash.new { |h,k| fail "Unknown option #{k}" }
         @cast = {}

         reg :database_file, 'Database file for storing ektoplazm metadata',
            File.join(CONFIG_DIR, 'meta.db'),
            File.method(:expand_path)

         reg :log_file, 'File used for logging',
            File.join(CONFIG_DIR, 'ektoplayer.log'),
            File.method(:expand_path)

         reg :temp_dir,
            %{Temporary dir for downloading mp3 files.
              They will be moved to `cache_dir` after the download completed and was successful.
              Directory will be created if it does not exist, parent directories will not be created.},
            '/tmp/.ektoplazm',
            File.method(:expand_path)

         reg :cache_dir,
            'Directory for storing cached mp3 files',
            File.join(Dir.home, '.cache', 'ektoplayer'),
            File.method(:expand_path)

         reg :archive_dir,
            'Where to search for downloaded MP3 archives',
            File.join(CONFIG_DIR, 'archives'),
            File.method(:expand_path)

         reg :download_dir,
            'Where to store downloaded MP3 archives', '/tmp',
            File.method(:expand_path)

         reg :auto_extract_to_archive_dir,
            %{Enable/disable automatic extraction of downloaded MP3
             archives from `download_dir' to `archive_dir'}, true

         reg :delete_after_extraction,
            %{In combination `with auto_extract_to_archive_dir':
             Delete zip archive after successful extraction}, true

         reg :playlist_load_newest,
            %{How many tracks from database should be added to
              the playlist on application start.}, 1000

         reg :use_cache,
            %{Enable/disable local mp3 cache.
              If this option is disabled, the downloaded mp3 files won't be moved
              from `cache_dir`. Instead they will reside in `temp_dir` and will
              be deleted on application exit.}, true

         reg :prefetch,
            'Enable prefetching the next track do be played', true

         reg :small_update_pages,
            'How many pages should be fetched after start', 5

         reg :use_colors,
            'Choose color capabilities. auto|mono|8|256', 'auto',
            lambda { |v| 
               { 'auto' => :auto, 'mono' => 0,
                 '8' => 8, '256' => 256 }[v] or fail 'invalid value'
            }

         reg :audio_system,
            'Set output audio system. See option `-o` in mpg123(1)',
            'pulse,alsa,jack,oss'

         reg :threads,
            'Number of download threads during database update',
            20, lambda { |v| fail if Integer(v) < 1; Integer(v) }

         # - Playlist
         reg 'playlist.format', 'Format of playlist columns',
            DEFAULT_PLAYLIST_FORMAT, ColumnFormat.method(:parse_column_format)

         reg 'playlist.format_256', 'Format of playlist columns (256 colors)',
            DEFAULT_PLAYLIST_FORMAT_256, ColumnFormat.method(:parse_column_format)

         # - Browser
         reg 'browser.format', 'Format of browser columns',
            DEFAULT_PLAYLIST_FORMAT, ColumnFormat.method(:parse_column_format)

         reg 'browser.format_256', 'Format of browser columns (256 colors)',
            DEFAULT_PLAYLIST_FORMAT_256, ColumnFormat.method(:parse_column_format)

         # - Progressbar
         reg 'progressbar.display',
            'Enable/disable progressbar', true

         reg 'progressbar.progress_char',
            'Character used for displaying playing progress', ?~

         reg 'progressbar.rest_char',
            'Character used for the rest of the line', ?~

         # - Playinginfo
         reg 'playinginfo.display',
            'Enable/display playinginfo', true

         reg 'playinginfo.format_top',
             'Format of first line in playinginfo',
             DEFAULT_PLAYINGINFO_FORMAT_TOP,
             ColumnFormat.method(:parse_simple_format)

         reg 'playinginfo.format_top_256',
             'Format of first line in playinginfo (256 colors)',
             DEFAULT_PLAYINGINFO_FORMAT_TOP_256,
             ColumnFormat.method(:parse_simple_format)

         reg 'playinginfo.format_bottom',
             'Format of second line in playinginfo',
             DEFAULT_PLAYINGINFO_FORMAT_BOTTOM,
             ColumnFormat.method(:parse_simple_format)

         reg 'playinginfo.format_bottom_256',
             'Format of second line in playinginfo (256 colors)',
             DEFAULT_PLAYINGINFO_FORMAT_BOTTOM_256,
             ColumnFormat.method(:parse_simple_format)

         # - Tabbar
         reg 'tabbar.display',       
            'Enable/disable tabbar', true

         reg 'tabs.widgets', 'Specify widget order of tabbar (left to right)',
            'splash,playlist,browser,info,help',
            lambda { |v| v.split(/\s*,\s*/).map(&:to_sym) }

         reg 'main.widgets', 'Specify widgets to show (up to down)',
            'playinginfo,tabbar,windows,progressbar',
            lambda { |v| v.split(/\s*,\s*/).map(&:to_sym) }
      end

      def get(key)  @options[key]  end
      def [](key)   @options[key]  end

      def set(option, value)
         option = option.to_sym
         current_value = get(option)

         if cast = @cast[option]
            @options[option] = cast.call(value)
         else
            if current_value.is_a?Integer
               @options[option] = Integer(value)
            elsif current_value.is_a?Float
               @options[option] = Float(value)
            elsif current_value.is_a?TrueClass or current_value.is_a?FalseClass
               fail 'invalid bool' unless %w(true false).include? value
               @options[option] = (value == 'true')
            else
               @options[option] = value
            end
         end

         @options[option].freeze
      rescue
         fail "Invalid value '#{value}' for '#{option}': #{$!}"
      end

      def parse(file, bindings, theme)
         callbacks = {
           set:        self.method(:set),
           bind:       bindings.method(:bind),
           unbind:     bindings.method(:unbind),
           unbind_all: bindings.method(:unbind_all),
           color:      theme.method(:color),
           color_256:  theme.method(:color_256),
           color_mono: theme.method(:color_mono)
         }
         callbacks.default_proc = proc { fail 'unknown command' }
         callbacks.freeze

         open(file, ?r).readlines.each do |line|
            line.chomp!
            next if line.empty? or line.start_with?(?#)
            command, *args = line.shellsplit

            begin
               cb = callbacks[command.to_sym]
               cb.call(*args)
            rescue
               fail "#{file}:#{$.}: #{command}: #{$!}"
            end
         end
      end
   end
end

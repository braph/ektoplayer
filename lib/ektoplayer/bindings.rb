require 'set'
require 'curses'

module Ektoplayer
   # Keybinding storage.
   #
   # Provides access for changing keybinds (with collision detection):
   #   bind(), unbind()
   #
   # Provides binding these keys to widgets
   #   bind_section_to_widget(), bind_to_widget()
   #
   class Bindings
      attr_reader :bindings, :commands

      def register(command, description)
         @commands[command.to_sym] = description.freeze
      end
      alias :reg :register

      def initialize
         @commands = {}

         reg 'quit',    'Quit the program'
         reg 'refresh', 'Refresh the screen'
         reg 'reload',  'Apply database changes to browser'
         reg 'update',  'Start a database update'

         reg 'player.stop',               'Stop playing'
         reg 'player.toggle',             'Toggle play/pause'
         reg 'player.forward',            'Seek forward'
         reg 'player.backward',           'Seek backward'

         reg 'tabs.next',                 'Select next tab'
         reg 'tabs.prev',                 'Select previous tab'

         reg 'browser.enter',             'Enter selected directory'
         reg 'browser.add_to_playlist',   'Add tracks under cursor to playlist'
         reg 'browser.back',              'Change to parent directory'

         reg 'playinginfo.toggle',        'Toggle playinginfo visibility'
         reg 'progressbar.toggle',        'Toggle progressbar visibility'
         reg 'volumemeter.toggle',        'Toggle volumemeter visibility'
         reg 'tabbar.toggle',             'Toggle tabbar visibility'

         reg 'playlist.goto_current',     'Go to current playing track'
         reg 'playlist.clear',            'Delete all items in playlist'
         reg 'playlist.delete',           'Delete selected track from playlist'
         reg 'playlist.download_album',   'Download album archive for selected track'
         reg 'playlist.play',             'Play selected track'
         reg 'playlist.reload',           'Force redownload of selected track'
         reg 'playlist.play_next',        'Play next track in playlist'
         reg 'playlist.play_prev',        'Play previous track in playlist'

         %w(info help browser playlist splash).each do |w|
            reg("#{w}.show", "Show #{w}")
         end

         {      up: 'Move cursor up',      down: 'Move cursor down',
           page_up: 'Scroll page up', page_down: 'Scroll page down',
               top: 'Move to top',       bottom: 'Move to bottom'
         }.each do |cmd, desc|
            %w(browser info help playlist).each { |w| reg("#{w}.#{cmd}", desc) }
         end

         { search_up: 'Start search upwards',     search_next: 'Goto next search result',
           search_down: 'Start search downwards', search_prev: 'Goto previous search result'
         }.each do |cmd, desc|
            %w(browser playlist).each { |w| reg("#{w}.#{cmd}", desc) }
         end

         @bindings = {
            global: {
               :'splash.show'             => [?`, ?^                         ],
               :'playlist.show'           => [?1                             ],
               :'browser.show'            => [?2                             ],
               :'info.show'               => [?3                             ],
               :'help.show'               => [?4                             ],

               :'playinginfo.toggle'      => [         Curses::KEY_F2        ],
               :'progressbar.toggle'      => [         Curses::KEY_F3        ],
               :'tabbar.toggle'           => [         Curses::KEY_F4        ],
               :'volumemeter.toggle'      => [         Curses::KEY_F5        ],

               :'player.forward'          => [?f,      Curses::KEY_RIGHT     ],
               :'player.backward'         => [?b,      Curses::KEY_LEFT      ],
               :'player.stop'             => [?s                             ],
               :'player.toggle'           => [?p                             ],

               :'playlist.play_next'      => [?>                             ],
               :'playlist.play_prev'      => [?<                             ],

               :'tabs.next'               => [?l                             ],
               :'tabs.prev'               => [?h                             ],

               :quit                      => [?q                             ],
               :refresh                   => ['^l'                           ],
               :reload                    => ['^r'                           ],
               :update                    => [?U                             ]},
            playlist: {
               # movement
               :'playlist.top'            => [?g,      Curses::KEY_HOME      ],
               :'playlist.bottom'         => [?G,      Curses::KEY_END       ],
               :'playlist.up'             => [?k,      Curses::KEY_UP        ],
               :'playlist.down'           => [?j,      Curses::KEY_DOWN      ],
               :'playlist.page_down'      => ['^d',    Curses::KEY_NPAGE     ],
               :'playlist.page_up'        => ['^u',    Curses::KEY_PPAGE     ],
               # search
               :'playlist.search_next'    => [?n                             ],
               :'playlist.search_prev'    => [?N                             ],
               :'playlist.search_up'      => [??                             ],
               :'playlist.search_down'    => [?/                             ],
               # playlist
               :'playlist.play'           => [         Curses::KEY_ENTER     ],
               :'playlist.download_album' => [?$                             ],
               :'playlist.reload'         => [?r                             ],
               :'playlist.goto_current'   => [?o                             ],
               :'playlist.clear'          => [?c                             ],
               :'playlist.delete'         => [?d                             ],
               # other
               :'player.toggle'           => [' '                            ]},
            browser: {
               # movement
               :'browser.top'             => [?g,      Curses::KEY_HOME      ],
               :'browser.bottom'          => [?G,      Curses::KEY_END       ],
               :'browser.up'              => [?k,      Curses::KEY_UP        ],
               :'browser.down'            => [?j,      Curses::KEY_DOWN      ],
               :'browser.page_up'         => ['^u',    Curses::KEY_PPAGE     ],
               :'browser.page_down'       => ['^d',    Curses::KEY_NPAGE     ],
               # search
               :'browser.search_next'     => [?n                             ],
               :'browser.search_prev'     => [?N                             ],
               :'browser.search_up'       => [??                             ],
               :'browser.search_down'     => [?/                             ],
               # browser
               :'browser.add_to_playlist' => [' ', ?a                        ],
               :'browser.enter'           => [?E,      Curses::KEY_ENTER     ],
               :'browser.back'            => [?B,      Curses::KEY_BACKSPACE ]},
            help: {
               :'help.top'                => [?g,      Curses::KEY_HOME      ],
               :'help.bottom'             => [?G,      Curses::KEY_END       ],
               :'help.up'                 => [?k,      Curses::KEY_UP        ],
               :'help.down'               => [?j,      Curses::KEY_DOWN      ],
               :'help.page_up'            => ['^u',    Curses::KEY_PPAGE     ],
               :'help.page_down'          => ['^d',    Curses::KEY_NPAGE     ]},
            info: {
               :'info.top'                => [?g,      Curses::KEY_HOME      ],
               :'info.bottom'             => [?G,      Curses::KEY_END       ],
               :'info.up'                 => [?k,      Curses::KEY_UP        ],
               :'info.down'               => [?j,      Curses::KEY_DOWN      ],
               :'info.page_up'            => ['^u',    Curses::KEY_PPAGE     ],
               :'info.page_down'          => ['^d',    Curses::KEY_NPAGE     ]},
            splash: {}
         }

         @bindings.default_proc = proc { |h,k| fail "Unknown widget #{k}" }
         @bindings.each do |widget, hash|
            hash.default_proc = proc { |h,k| h[k] = [] }
            hash.values.each do |keys|
               keys.map! { |key| parse_key(key) }
            end
         end
      end

      def keyname(key)
         return 'SPACE'  if key.to_s == ' '
         return key.to_s if key.is_a? Symbol

         name = Curses.keyname(key)
         if name.start_with? 'KEY_'
            name.sub('KEY_', '').sub(/\((\d+)\)/, '\1')
         else
            name
         end
      end

      def parse_key(key)
         if key.is_a? Integer
            key
         elsif key.size == 1
            key.to_sym
         elsif key.size == 2 and key.start_with?(?^)
            Curses.const_get("KEY_CTRL_#{key[1].upcase}")
         elsif key =~ /^(key_)?space$/i
            :' '
         else
            key = key.upcase.tr(?-, ?_)
            key = "KEY_#{key}" unless key.start_with?('KEY_')
            Curses.const_get(key)
         end
      rescue NameError
         fail "Unknown key: #{key}"
      end

      def bind(widget, key, command)
         widget, command = widget.to_sym, command.to_sym
         fail "Unknown command #{command}" unless @commands.include? command

         @bindings[widget][command].delete parse_key(key) rescue nil
         @bindings[widget][command] << parse_key(key)
         check_collisions
      end

      def unbind(widget, key)
         @bindings[widget.to_sym].each do |command, keys|
            keys.delete( (parsed_key ||= parse_key(k)) )
         end
      end

      def unbind_all
         @bindings.each do |widget, commands|
            commands.clear
         end
      end

      def bind_view(section, view, view_operations, operations)
         @bindings[section.to_sym].each do |command, keys|
            keys.each do |key|
               meth = view_operations.method(command) rescue operations.method(command)
               view.keys.on(key, &meth)
            end
         end
      end

      private def check_collisions
         global_keys = @bindings[:global].values.flatten
         global_keys.each do |k|
            fail "Double binding in 'global', key #{keyname(k)}" if global_keys.count(k) > 1
         end

         @bindings.each_pair do |widget, commands|
            next if widget == :global
            widget_keys = commands.values.flatten
            widget_keys.each do |k|
               if widget_keys.count(k) > 1
                  fail "Double binding in '#{widget}', key `#{keyname(k)}`"
               end

               if global_keys.include? k
                  fail "Double binding in 'global <> #{widget}', key #{keyname(k)}"
               end
            end
         end
      end
   end
end

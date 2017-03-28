require 'set'
require_relative 'icurses'

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

         reg 'quit',                      'Quit the program'
         reg 'refresh',                   'Refresh the screen'
         reg 'reload',                    'Apply database changes to browser'
         reg 'update',                    'Start a database update'

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
           search_down: 'Start search downwards', search_prev: 'Goto previous search result',
           toggle_selection:  'Toggle multi line selection',
         }.each do |cmd, desc|
            %w(browser playlist).each { |w| reg("#{w}.#{cmd}", desc) }
         end

         @bindings = { }
         @bindings[:global] = {
            :'splash.show'             => [?`, ?^                          ],
            :'playlist.show'           => [?1                              ],
            :'browser.show'            => [?2                              ],
            :'info.show'               => [?3                              ],
            :'help.show'               => [?4,      ICurses::KEY_F1        ],

            :'playinginfo.toggle'      => [?!, ?\\, ICurses::KEY_F2        ],
            :'progressbar.toggle'      => [?%, ?~,  ICurses::KEY_F3        ],
            :'tabbar.toggle'           => [?=,      ICurses::KEY_F4        ],

            :'player.forward'          => [?f,      ICurses::KEY_RIGHT     ],
            :'player.backward'         => [?b,      ICurses::KEY_LEFT      ],
            :'player.stop'             => [?s                              ],
            :'player.toggle'           => [?p                              ],

            :'playlist.play_next'      => [?>                              ],
            :'playlist.play_prev'      => [?<                              ],

            :'tabs.next'               => [?l, ?}, '^i'                    ],
            :'tabs.prev'               => [?h, ?{, 353                     ],

            :quit                      => [?q                              ],
            :refresh                   => ['^l'                            ],
            :reload                    => ['^r'                            ],
            :update                    => [?U                              ]
         }
         @bindings[:playlist] = {
            # movement
            :'playlist.top'            => [?g,      ICurses::KEY_HOME      ],
            :'playlist.bottom'         => [?G,      ICurses::KEY_END       ],
            :'playlist.up'             => [?k,      ICurses::KEY_UP        ],
            :'playlist.down'           => [?j,      ICurses::KEY_DOWN      ],
            :'playlist.page_down'      => ['^d',    ICurses::KEY_NPAGE     ],
            :'playlist.page_up'        => ['^u',    ICurses::KEY_PPAGE     ],
            # selection
            :'playlist.toggle_selection' => ['^v'                          ],
            # search
            :'playlist.search_next'    => [?n                              ],
            :'playlist.search_prev'    => [?N                              ],
            :'playlist.search_up'      => [??                              ],
            :'playlist.search_down'    => [?/                              ],
            # playlist
            :'playlist.play'           => [         ICurses::KEY_ENTER     ],
            :'playlist.download_album' => [?$                              ],
            :'playlist.reload'         => [?r                              ],
            :'playlist.goto_current'   => [?o                              ],
            :'playlist.clear'          => [?c                              ],
            :'playlist.delete'         => [?d                              ],
            # other
            :'player.toggle'           => [' '                             ]
         }
         @bindings[:browser] = {
            # movement
            :'browser.top'             => [?g,      ICurses::KEY_HOME      ],
            :'browser.bottom'          => [?G,      ICurses::KEY_END       ],
            :'browser.up'              => [?k,      ICurses::KEY_UP        ],
            :'browser.down'            => [?j,      ICurses::KEY_DOWN      ],
            :'browser.page_up'         => ['^u',    ICurses::KEY_PPAGE     ],
            :'browser.page_down'       => ['^d',    ICurses::KEY_NPAGE     ],
            # selection
            :'browser.toggle_selection' => ['^v'                           ],
            # search
            :'browser.search_next'     => [?n                              ],
            :'browser.search_prev'     => [?N                              ],
            :'browser.search_up'       => [??                              ],
            :'browser.search_down'     => [?/                              ],
            # browser
            :'browser.add_to_playlist' => [' ', ?a                         ],
            :'browser.enter'           => [         ICurses::KEY_ENTER     ],
            :'browser.back'            => [?B,      ICurses::KEY_BACKSPACE ]
         }
         @bindings[:help] = {
            :'help.top'                => [?g,      ICurses::KEY_HOME      ],
            :'help.bottom'             => [?G,      ICurses::KEY_END       ],
            :'help.up'                 => [?k,      ICurses::KEY_UP        ],
            :'help.down'               => [?j,      ICurses::KEY_DOWN      ],
            :'help.page_up'            => ['^u',    ICurses::KEY_PPAGE     ],
            :'help.page_down'          => ['^d',    ICurses::KEY_NPAGE     ]
         }
         @bindings[:info] = {
            :'info.top'                => [?g,      ICurses::KEY_HOME      ],
            :'info.bottom'             => [?G,      ICurses::KEY_END       ],
            :'info.up'                 => [?k,      ICurses::KEY_UP        ],
            :'info.down'               => [?j,      ICurses::KEY_DOWN      ],
            :'info.page_up'            => ['^u',    ICurses::KEY_PPAGE     ],
            :'info.page_down'          => ['^d',    ICurses::KEY_NPAGE     ]
         }
         @bindings[:splash] = {}

         @bindings.default_proc = proc { |h,k| fail "Unknown widget #{k}" }
         @bindings.each do |widget, hash|
            hash.default_proc = proc { |h,k| h[k] = [] }
            hash.values.each do |keys|
               keys.map!(&method(:parse_key))
            end
         end
      end

      def keyname(key)
         return 'SPACE' if (key == ' ' or key == 32)

         name = ICurses.keyname(key)
         if name.start_with? 'KEY_'
            name.sub('KEY_', '').delete('()')
         else
            name
         end
      end

      def parse_key(key)
         return key if key.is_a? Integer
         
         if key.size == 1
            return key.ord
         elsif key.size == 2 and key[0] == ?^
            return key[1].upcase.ord - 64
         elsif key =~ /^(key_)?space$/i
            return ' '.ord
         end

         begin
            return Integer(key) 
         rescue
            key = key.upcase.tr(?-, ?_)
            key = "KEY_#{key}" unless key.start_with?('KEY_')
            return ICurses.const_get(key)
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

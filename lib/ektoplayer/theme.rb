require_relative 'ui/colors'

module Ektoplayer
   class Theme
      attr_reader :current, :theme

      def initialize
         @theme, @current = {}, 0

         @theme[0] = {
            :default                   => [-1, -1                        ].freeze,
            :'url'                     => [:default, :default, :underline].freeze,
            :'tabbar.selected'         => [:default, :default, :bold     ].freeze
         }
         @theme[8] = {
            :default                   => [-1, -1                        ].freeze,
            :'url'                     => [:magenta, :default, :underline].freeze,

            :'info.head'               => [:blue, :default, :bold        ].freeze,
            :'info.tag'                => [:blue                         ].freeze,
            :'info.value'              => [:magenta                      ].freeze,
            :'info.description'        => [:blue                         ].freeze,
            :'info.download.file'      => [:blue                         ].freeze,
            :'info.download.percent'   => [:magenta                      ].freeze,
            :'info.download.error'     => [:red                          ].freeze,

            :'progressbar.progress'    => [:blue                         ].freeze,
            :'progressbar.rest'        => [:black                        ].freeze,

            :'tabbar.selected'         => [:blue                         ].freeze,
            :'tabbar.unselected'       => [:white                        ].freeze,

            :'list.item_even'          => [:blue                         ].freeze,
            :'list.item_odd'           => [:blue                         ].freeze,
            :'list.item_selection'     => [:magenta                      ].freeze,

            :'playinginfo.position'    => [:magenta                      ].freeze,
            :'playinginfo.state'       => [:cyan                         ].freeze,

            :'help.widget_name'        => [:blue, :default, :bold        ].freeze,
            :'help.key_name'           => [:blue                         ].freeze,
            :'help.command_name'       => [:magenta                      ].freeze,
            :'help.command_desc'       => [:yellow                       ].freeze
         }
         @theme[256] = {
            :'default'                 => [:white, 233                   ].freeze,
            :'url'                     => [97, :default, :underline      ].freeze,

            :'info.head'               => [32, :default, :bold           ].freeze,
            :'info.tag'                => [74                            ].freeze,
            :'info.value'              => [67                            ].freeze,
            :'info.description'        => [67                            ].freeze,
            :'info.download.file'      => [75                            ].freeze,
            :'info.download.percent'   => [68                            ].freeze,
            :'info.download.error'     => [:red                          ].freeze,

            :'progressbar.progress'    => [23                            ].freeze,
            :'progressbar.rest'        => [:black                        ].freeze,

            :'tabbar.selected'         => [75                            ].freeze,
            :'tabbar.unselected'       => [250                           ].freeze,

            :'list.item_even'          => [26                            ].freeze,
            :'list.item_odd'           => [25                            ].freeze,
            :'list.item_selection'     => [97                            ].freeze,

            :'playinginfo.position'    => [97                            ].freeze,
            :'playinginfo.state'       => [37                            ].freeze,

            :'help.widget_name'        => [33                            ].freeze,
            :'help.key_name'           => [75                            ].freeze,
            :'help.command_name'       => [68                            ].freeze,
            :'help.command_desc'       => [29                            ].freeze
         }
         @theme.freeze
      end

      def color(name, *defs, theme: 8)
         defs.map! { |d| Integer(d) rescue d.to_sym }
         @theme[theme][name.to_sym] = defs.freeze
      end

      def color_mono(*args)  color(*args, theme: 0)     end
      def color_256(*args)   color(*args, theme: 256)   end

      def get(theme_def)     UI::Colors.get(theme_def)  end
      def [](theme_def)      UI::Colors.get(theme_def)  end

      def use_colors(colors)
         fail 'unknown theme' unless @theme[colors]
         @current = colors

         UI::Colors.reset
         UI::Colors.default_fg(@theme[@current][:default][0])
         UI::Colors.default_bg(@theme[@current][:default][1])

         @theme.values.map(&:keys).flatten.each do |name|
            defs ||= @theme[256][name] if @current == 256
            defs ||= @theme[8][name]   if @current >= 8
            defs ||= @theme[0][name]

            #unless defs
            #   defs ||= @theme[256][:default] if @current == 256
            #   defs ||= @theme[8][:default]   if @current >= 8
            #   defs ||= @theme[0][:default]
            #end

            UI::Colors.set(name, *defs)
         end
      end
   end
end

require_relative 'ui/colors'

module Ektoplayer
   class Theme
      attr_reader :current, :theme

      def initialize
         @current = 0
         @theme = {
            0 =>   { default: [-1, -1].freeze,
               :'url'                     => [-1, -1, :underline      ].freeze,
               :'tabbar.selected'         => [-1, -1, :bold           ].freeze},
            8 =>   { default: [-1, -1].freeze,
               :'url'                     => [:magenta, -1, :underline].freeze,

               :'info.head'               => [:blue, -1, :bold        ].freeze,
               :'info.tag'                => [:blue                   ].freeze,
               :'info.value'              => [:magenta                ].freeze,
               :'info.description'        => [:blue                   ].freeze,
               :'info.download.file'      => [:blue                   ].freeze,
               :'info.download.percent'   => [:magenta, -1            ].freeze,
               :'info.download.error'     => [:red                    ].freeze,

               :'progressbar.progress'    => [:blue                   ].freeze,
               :'progressbar.rest'        => [:black                  ].freeze,

               :'volumemeter.level'       => [:magenta                ].freeze,
               :'volumemeter.rest'        => [:black                  ].freeze,

               :'tabbar.selected'         => [:blue                   ].freeze,
               :'tabbar.unselected'       => [:none                   ].freeze,

               :'list.item_even'          => [:blue                   ].freeze,
               :'list.item_odd'           => [:blue                   ].freeze,

               :'playinginfo.position'    => [:magenta                ].freeze,
               :'playinginfo.state'       => [:cyan                   ].freeze,

               :'help.widget_name'        => [:blue, -1, :bold        ].freeze,
               :'help.key_name'           => [:blue                   ].freeze,
               :'help.command_name'       => [:magenta                ].freeze,
               :'help.command_desc'       => [:yellow                 ].freeze},
            256 => { default: [-1, -1].freeze,
               :'url'                     => [97,  -1, :underline     ].freeze,

               :'info.head'               => [32, -1, :bold           ].freeze,
               :'info.tag'                => [74                      ].freeze,
               :'info.value'              => [67                      ].freeze,
               :'info.description'        => [67                      ].freeze,
               :'info.download.file'      => [75                      ].freeze,
               :'info.download.percent'   => [68                      ].freeze,
               :'info.download.error'     => [:red                    ].freeze,

               :'progressbar.progress'    => [23                      ].freeze,
               :'progressbar.rest'        => [236                     ].freeze,

               :'volumemeter.level'       => [:magenta                ].freeze,
               :'volumemeter.rest'        => [236                     ].freeze,

               :'tabbar.selected'         => [75                      ].freeze,
               :'tabbar.unselected'       => [250                     ].freeze,

               :'list.item_even'          => [:blue                   ].freeze,
               :'list.item_odd'           => [25                      ].freeze,

               :'help.widget_name'        => [33                      ].freeze,
               :'help.key_name'           => [75                      ].freeze,
               :'help.command_name'       => [68                      ].freeze,
               :'help.command_desc'       => [29                      ].freeze}
         }.freeze
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
         @theme.values.map(&:keys).flatten.each do |name|
            defs ||= @theme[256][name] if @current == 256
            defs ||= @theme[8][name]   if @current >= 8
            defs ||= @theme[0][name]

            unless defs
               defs ||= @theme[256][:default] if @current == 256
               defs ||= @theme[8][:default]   if @current >= 8
               defs ||= @theme[0][:default]
            end

            UI::Colors.set(name, *defs)
         end
      end
   end
end

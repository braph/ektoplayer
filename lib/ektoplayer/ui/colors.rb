require_relative '../icurses'

module UI
   class ColorFader
      def initialize(colors)
         @colors = colors.map { |attrs| UI::Colors.set(nil, *attrs) }
      end

      def fade(size)   ColorFader._fade(@colors, size)   end
      def fade2(size)  ColorFader._fade2(@colors, size)  end

      def ColorFader._fade(colors, size)
         return [] if size < 1
         return [colors[0]] * size if colors.size == 1

         part_len = (size / colors.size)
         diff = size - part_len * colors.size

         (colors.size - 1).times.map do |color_i|
            [colors[color_i]] * part_len
         end.flatten.concat( [colors[-1]] * (part_len + diff) )
      end

      def ColorFader._fade2(colors, size)
         half = size / 2
         ColorFader._fade(colors, half) + ColorFader._fade(colors.reverse, size - half)
      end
   end

   class Colors
      COLORS = {
         none:     -1, 
         white:    ICurses::COLOR_WHITE,
         black:    ICurses::COLOR_BLACK,
         red:      ICurses::COLOR_RED,
         blue:     ICurses::COLOR_BLUE,
         cyan:     ICurses::COLOR_CYAN,
         green:    ICurses::COLOR_GREEN,
         yellow:   ICurses::COLOR_YELLOW,
         magenta:  ICurses::COLOR_MAGENTA
      }
      COLORS.default_proc = proc do |h, key|
         fail "Unknown color #{key}" unless key.is_a?Integer
         key
      end
      COLORS.freeze

      ATTRIBUTES = {
         bold:  ICurses::A_BOLD,  standout:  ICurses::A_STANDOUT,
         blink: ICurses::A_BLINK, underline: ICurses::A_UNDERLINE
      }
      ATTRIBUTES.default_proc = proc do |h,key|
         fail "Unknown attribute #{key}" unless key.is_a?Integer
         key
      end
      ATTRIBUTES.freeze

      def self.start
         @@id           ||= 1
         @@aliases      ||= {}
         @@volatile     ||= {}
         @@volatile_ids ||= {}
         @@cached       ||= Hash.new { |h,k| h[k] = {} }
         @@default_fg = @@default_bg = -1
      end
      def self.reset; self.start end

      def self.default_fg(color)
         @@default_fg = COLORS[color]
      end

      def self.default_bg(color)
         @@default_bg = COLORS[color]
      end

      def self.default_colors(fg = -1, bg = -1)
         self.default_fg(fg)
         self.default_bg(bg)
      end

      def self.init_pair_cached(fg, bg)
         if !fg or fg == :default
            fg = @@default_fg
         else
            fg = COLORS[fg]
         end

         if !bg or bg == :default
            bg = @@default_bg
         else
            bg = COLORS[bg]
         end

         unless id = @@cached[fg][bg]
            id = @@cached[fg][bg] = @@id
            @@id += 1
         end

         ICurses.init_pair(id, fg, bg) #or fail
         ICurses.color_pair(id)
      end

      def self.add_attributes(*attrs)
         flags = 0
         attrs.each { |attr| flags |= ATTRIBUTES[attr] }
         flags
      end

      def self.[](name)   @@aliases[name] || 0  end
      def self.get(name)  @@aliases[name] || 0  end
      
      def self.set(name, fg, bg = nil, *attrs)
         @@aliases[name] = self.init_pair_cached(fg, bg)
         attrs.each { |attr| @@aliases[name] |= ATTRIBUTES[attr] }
         @@aliases[name]
      end

      def self.get_volatile(name)
         @@volatile[name] || 0
      end

      def self.set_volatile(name, fg, bg)
         fg, bg = COLORS[fg], COLORS[bg]

         unless id = @@volatile_ids[name]
            id = @@volatile_ids[name] = @@id
            @@id += 1
         end

         @@volatile[name] = ICurses.init_pair(id, fg, bg)
      end
   end
end

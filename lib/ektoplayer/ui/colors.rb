require 'curses'

module UI
   class ColorFader
      def initialize(colors)
         @colors = colors.map { |attrs| UI::Colors.set(nil, *attrs) }
      end

      def fade(size)   ColorFader._fade(@colors, size)   end
      def fade2(size)  ColorFader._fade2(@colors, size)  end

      def ColorFader._fade(colors, size)
         return [] if size < 1

         part_len = (size / colors.size)
         diff = size - part_len * colors.size

         (colors.size - 1).times.map do |color_i|
            [colors[color_i]] * part_len
         end.flatten.concat( [colors[-1]] * (part_len + diff) )
      end

      def ColorFader._fade2(colors, size)
         half = size / 2
         ColorFader._fade(colors, half) + ColorFader._fade(colors, size - half).reverse
      end
   end

   class Colors
      COLORS = {
         none: -1, default: -1, nil => -1,
         white:    Curses::COLOR_WHITE,
         black:    Curses::COLOR_BLACK,
         red:      Curses::COLOR_RED,
         blue:     Curses::COLOR_BLUE,
         cyan:     Curses::COLOR_CYAN,
         green:    Curses::COLOR_GREEN,
         yellow:   Curses::COLOR_YELLOW,
         magenta:  Curses::COLOR_MAGENTA
      }
      COLORS.default_proc = proc do |h, key|
         fail "Unknown color #{key}" unless key.is_a?Integer
         key
      end
      COLORS.freeze

      ATTRIBUTES = {
         bold:  Curses::A_BOLD,  standout:  Curses::A_STANDOUT,
         blink: Curses::A_BLINK, underline: Curses::A_UNDERLINE
      }
      ATTRIBUTES.default_proc = proc { |h,k| k }
      ATTRIBUTES.freeze

      def self.start
         @@id           ||= 1
         @@aliases      ||= {}
         @@volatile     ||= {}
         @@volatile_ids ||= {}
         @@cached       ||= Hash.new { |h,k| h[k] = {} }
      end
      def self.reset; self.start end

      def self.init_pair_cached(fg, bg)
         fg, bg = COLORS[fg], COLORS[bg]

         unless id = @@cached[fg][bg]
            id = @@cached[fg][bg] = @@id
            @@id += 1
         end

         Curses.init_pair(id, fg, bg) #or fail
         Curses.color_pair(id)
      end

      def self.add_attributes(*attrs)
         flags = 0
         attrs.each { |attr| flags |= ATTRIBUTES[attr] }
         flags
      end

      def self.[](name)   @@aliases[name] || 0  end
      def self.get(name)  @@aliases[name] || 0  end
      
      def self.set(name, fg, bg = -1, *attrs)
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

         @@volatile[name] = Curses.init_pair(id, fg, bg)
      end
   end
end

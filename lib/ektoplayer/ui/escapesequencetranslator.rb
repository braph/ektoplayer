require_relative '../icurses'

module UI
   class EscapeSequenceTranslator
      KEYS = {
         ?\r     => ICurses::KEY_ENTER,
         ?\r.ord => ICurses::KEY_ENTER
      }

      def self.reg(key, fallback, curses_key)
         code = `tput #{key} 2>/dev/null` rescue ''
         code = fallback if code.empty?
         KEYS[code] = curses_key if not code.empty?
      end
      
      self.reg('kcuu1', "\033[A",  ICurses::KEY_UP)
      self.reg('kcud1', "\033[B",  ICurses::KEY_DOWN)
      self.reg('kcuf1', "\033[C",  ICurses::KEY_RIGHT)
      self.reg('kcub1', "\033[D",  ICurses::KEY_LEFT)
      self.reg('khome', "\033[1~", ICurses::KEY_HOME)
      self.reg('kich1', "\033[2~", ICurses::KEY_IC)
      self.reg('kdch1', "\033[3~", ICurses::KEY_DC)
      self.reg('kend',  "\033[4~", ICurses::KEY_END)
      self.reg('kpp',   "\033[5~", ICurses::KEY_PPAGE)
      self.reg('knp',   "\033[6~", ICurses::KEY_NPAGE)
      (0..60).each do |i|
         begin
            self.reg("kf#{i}", '', ICurses.const_get("KEY_F#{i}"))
         rescue 
         end
      end

      KEYS.freeze

      def self.to_curses(key)
         if KEYS.include? key
            KEYS[key]
         elsif key.is_a? Integer
            key
         elsif ((key.is_a? String or key.is_a? Array) and key[0] == 27.chr and key[1] == ?[ and key[2] == ?M)
            ICurses::IMouseEvent.new(bstate: ICurses::BUTTON1_CLICKED, x: key[4].ord - 33, y: key[5].ord - 33)
         elsif key.size == 1
            key.ord rescue nil
         end
      end
   end
end

require 'ncursesw'

Ncurses.initscr#; Ncurses.endwin

module Ncurses
   class WINDOW
      def getch
         return Ncurses::wgetch(self)
         y, x = Ncurses::getcury(self), Ncurses::getcurx(self)
         c = Ncurses::wgetch(self)
         Ncurses::wmove(self, y, x)
         c
      end
   end
end

module ICurses
   include Ncurses

   (Ncurses.public_methods - public_methods).each do |method|
      define_singleton_method(method, &Ncurses.method(method))
   end

   def initscr; end
   module_function :initscr
   
   def mousemask(mask, *_)
      Ncurses.mousemask(mask, [])
   end
   module_function :mousemask

   IWindow = Ncurses::WINDOW
end

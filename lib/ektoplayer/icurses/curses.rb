require 'curses'

module Curses
   def Curses.initscr; init_screen  end
   def Curses.endwin;  close_screen end

   def Curses.newwin(*a) Curses::Window.new(*a) end
   def Curses.newpad(*a) Curses::Pad.new(*a)    end

   class Window
      def mvaddstr(y, x, s)
         move(y, x)
         addstr(s)
      end

      %w(curx cury maxx maxy begx begy).each do |method|
         alias_method :"get#{method}", method.to_sym
      end

      def leaveok(*_);   end # Curses does not 
      def notimeout(*_); end # provide these functions

      alias :timeout :timeout=
      alias :nodelay :nodelay=

      def bkgd(attr)
         @bkgd_color = attr
      end
      alias :bkgdset :bkgd

      def erase
         setpos(0, 0)
         attrset((@bkgd_color or 0))
         addstr(' ' * (maxx * maxy))
         attroff((@bkgd_color or 0))
         setpos(0, 0)
      end

      alias :mvwin :move # 'fix' this Gem
      def move(y, x)
         setpos(y, x)
      end
   end

   class Pad < Window
      alias :pnoutrefresh :noutrefresh
      alias :prefresh     :refresh
   end
end

module ICurses
   include Curses

   (Curses.public_methods - public_methods).each do |method|
      define_singleton_method(method, &Curses.method(method))
   end

   def mousemask(mask, *a); Curses.mousemask(mask) end
   module_function :mousemask

   def getmouse(mevent=nil)
      if mevent = Curses.getmouse()
         return IMouseEvent.new(mevent)
      end
   end
   module_function :getmouse

   IWindow = Curses::Window
end

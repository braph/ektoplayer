require $USING_CURSES

Ncurses.initscr

module Ncurses
   class IWindow
      def initialize(w)
         @w = w
      end

      def getch
         return Ncurses::wgetch(self)
         y, x = Ncurses::getcury(self), Ncurses::getcurx(self)
         c = Ncurses::wgetch(self)
         Ncurses::wmove(self, y, x)
         c
      end

      %w(getcurx getcury getmaxx getmaxy getbegx getbegy
         clearok idlok idcok immedok leaveok setscrreg scrollok nl nonl
         keypad nodelay notimeout prefresh pnoutrefresh).each do |meth|
         define_method(meth) do |*args|
            Ncurses.send(meth, @w, *args)
         end
      end

      Ncurses.public_methods.each do |meth|
         if meth =~ /^(mv)?w/ 
            define_method(meth) do |*args|
               Ncurses.send(meth, @w, *args)
            end

            next if meth =~ /win$/

            define_method(meth.to_s.sub(?w, '')) do |*args|
               Ncurses.send(meth, @w, *args)
            end
         end
      end

      if $USING_CURSES == 'ncurses'
         ### FIX: 'attrset' in ncurses seems broken?
         def attrset(attributes)
            Ncurses.send(:wattr_get, @w, old_a=[], old_c=[], nil)
            Ncurses.send(:wattroff, @w, old_a[0] | old_c[0])
            Ncurses.send(:wattron, @w, attributes)
         end
      end
   end
end

module ICurses
   include Ncurses

   def method_missing(m, *a)
      Ncurses.send(m, *a)
   rescue NoMethodError
      Ncurses.send(m.downcase, *a)
   end
   module_function :method_missing

   def initscr; end # do nothing
   module_function :initscr

   def stdscr
      ICurses::IWindow.new( Ncurses.stdscr )
   end
   module_function :stdscr

   def newwin(*a)
      ICurses::IWindow.new( Ncurses.newwin(*a) )
   end
   module_function :newwin

   def newpad(*a)
      ICurses::IWindow.new( Ncurses.newpad(*a) )
   end
   module_function :newpad

   def mousemask(mask, *_)
      Ncurses.mousemask(mask, [])
   end
   module_function :mousemask

   def getmouse(mevent=nil)
      mevent = Ncurses::MEVENT.new
      if Ncurses.getmouse(mevent) > -1
         return IMouseEvent.new(mevent)
      end
   end
   module_function :getmouse

   IWindow = Ncurses::IWindow
end

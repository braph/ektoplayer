require 'ffi-ncurses'

module FFI::NCurses
   alias_method :_newwin, :newwin
   def newwin(*a)
      IWindow.new(_newwin(*a))
   end
   module_function :newwin

   alias_method :_newpad, :newpad
   def newpad(*a)
      IWindow.new(_newpad(*a))
   end
   module_function :newpad

   alias_method :_stdscr, :stdscr
   def stdscr
      IWindow.new(_stdscr)
   end
   module_function :stdscr

   alias_method :_mousemask, :mousemask
   def mousemask(mask, *_)
      _mousemask(mask, nil)
   end
   module_function :mousemask

   alias_method :_getmouse, :getmouse
   def getmouse(mevent=nil)
      mevent = FFI::NCurses::Mouse::MEVENT.new
      if _getmouse(mevent) > -1
         return IMouseEvent.new(mevent)
      end
   end
   module_function :getmouse


   class Window
      def initialize(w)
         @w = w
      end

      FFI::NCurses.public_methods.each do |method|
         if method =~ /^(mv)?w/ 
            define_method(method) do |*args|
               FFI::NCurses.send(method, @w, *args)
            end

            next if method =~ /win$/

            define_method(method.to_s.sub(?w, '')) do |*args|
               FFI::NCurses.send(method, @w, *args)
            end
         end
      end

      %w(getcurx getcury getmaxx getmaxy getbegx getbegy
         keypad nodelay notimeout prefresh pnoutrefresh).each do |meth|

         define_method(meth) do |*args|
            FFI::NCurses.send(meth, @w, *args)
         end
      end
   end

   IWindow = Window
end

ICurses = FFI::NCurses

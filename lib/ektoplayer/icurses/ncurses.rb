require 'ncurses'

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

      %w(getcurx getcury getmaxx getmaxy getbegx getbegy
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
               Ektoplayer::Application.log(self, meth) unless meth =~ /attr/
               Ncurses.send(meth, @w, *args)
            end
         end
      end

      #(Ncurses.public_methods - public_methods).each do |meth|

      #   define_method(meth) do |*args|
      #      Ncurses.send(meth, @w, *args)
      #   end
      #end
   end
end

module ICurses
   include Ncurses

   (Ncurses.public_methods - public_methods).each do |method|
      define_singleton_method(method, &Ncurses.method(method))
      module_function method
   end

   def initscr; end
   module_function :initscr

   def mousemask(mask, *_)
      Ncurses.mousemask(mask, [])
   end
   module_function :mousemask

   IWindow = Ncurses::WINDOW
end

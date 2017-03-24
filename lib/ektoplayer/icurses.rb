found_curses = false

%w(curses ffi_ncurses curses ncurses ncursesw).each do |f|
   begin
      require_relative "icurses/#{f}" 
      found_curses = true
      break
   rescue LoadError
   end
end

fail %{No interface for curses found. Please either do
   gem install curses
      or
   gem install ffi-ncurses
} unless found_curses

# ===================================================
module ICurses
   class IMouseEvent
      attr_accessor :x, :y, :z, :bstate

      def initialize(mouse_event=nil)
         from_mouse_event!(mouse_event)
      end

      def [](key)          send(key)               end
      def []=(key, value)  send("#{key}=", value)  end

      def from_mouse_event!(m)
         @x, @y, @z, @bstate = m.x, m.y, m.z, m.bstate 
      rescue
         @x, @y, @z, @bstate = m[:x], m[:y], m[:z], m[:bstate]
      rescue
         @x, @y, @z, @bstate = 0, 0, 0, 0
      end

      def update!(x: nil, y: nil, z: nil, bstate: nil)
         @x, @y, @z = (x or @x), (y or @y), (z or @z)
         @bstate = (bstate or @bstate)
      end
   end
end

module ICurses
   %w(lines cols colors init_pair color_pair).each do |meth| 
      meth_up = meth.upcase

      if not respond_to? meth
         alias_method(meth, meth_up)
         module_function(meth)
      elsif not respond_to? meth_up
         alias_method(meth_up, meth)
         module_function(meth_up)
      end
   end

   class IWindow
      unless respond_to? :<<
         alias_method(:<<, :addstr)
      end

      %w(curx cury maxx maxy begx begy).each do |meth|
         full = 'get' + meth
         if not respond_to? meth
            alias_method(meth, full)
         elsif not respond_to? full
            alias_method(full, meth)
         end
      end
   end
end


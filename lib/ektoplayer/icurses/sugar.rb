module ICurses
   class IMouseEvent
      attr_accessor :x, :y, :z, :bstate

      def initialize(mouse_event=nil, bstate: 0, x: 0, y: 0, z: 0)
         @x, @y, @z, @bstate = x, y, z, bstate
         from_mouse_event!(mouse_event)
      end

      def [](key)          send(key)               end
      def []=(key, value)  send("#{key}=", value)  end

      def from_mouse_event!(m)
         @x, @y, @z, @bstate = m.x, m.y, m.z, m.bstate 
      rescue
         begin @x, @y, @z, @bstate = m[:x], m[:y], m[:z], m[:bstate]
         rescue
         end
      end

      def update!(x: nil, y: nil, z: nil, bstate: nil)
         @x = x if x
         @y = y if y
         @z = z if z
         @bstate = bstate if bstate
      end
   end
end

module ICurses
   %w(lines cols colors init_pair color_pair).each do |meth| 
      meth_up = meth.upcase

      if not respond_to? meth
         alias_method(meth, meth_up) rescue (
            define_method(meth) do |*args|
               method_missing(meth_up, *args)
            end
         )
         module_function(meth)
      elsif not respond_to? meth_up
         alias_method(meth_up, meth) rescue (
            define_method(meth_up) do |*args|
               method_missing(meth, *args)
            end
         )
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

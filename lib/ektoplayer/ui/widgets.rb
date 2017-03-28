module UI
   class Widget
      WANT_REFRESH, WANT_REDRAW, WANT_LAYOUT = 1, 2, 4

      attr_reader  :pos, :size
      def events;          @events ||= Events.new.no_auto_create       end
      def keys;            @keys   ||= Events.new                      end
      def mouse;           @mouse  ||= MouseEvents.new                 end
      def mouse_section;   @mouse_section ||= MouseSectionEvents.new   end

      def initialize(parent: nil, size: nil, pos: nil, visible: true)
         if !parent and (!size or !pos)
            fail ArgumentError, "must provide 'size:' and 'pos:' if 'parent:' is nil"
         end

         @parent, @visible, = parent, visible
         @size = (size or @parent.size.dup)
         @pos  = (pos  or @parent.pos.dup)
         @want, @lock = WANT_LAYOUT, Monitor.new
      end

      # Proxy method for creating a new widget object with the current
      # object as parent.
      def sub(class_type, **opts)
         class_type.new(parent: self, **opts)
      end

      # This method should be used each time a widget may modify
      # its window contents.
      #
      # It ensures that operations that modify the window (such
      # as draw, layout and refresh) are executed once and only once at the
      # end of this function.
      def with_lock
         lock; yield
      ensure
         unlock
      end

      def lock
         @lock.enter
      end

      def unlock
         return unless (@lock.exit rescue nil)

         if @want & WANT_LAYOUT > 0 
            layout;
            @want ^= WANT_LAYOUT
         end
         return   if not visible?

         if @want & WANT_REDRAW > 0
            draw
            @want ^= WANT_REDRAW
         end

         if @want > 0 #& WANT_REFRESH > 0
            Canvas.update_screen
            @want ^= WANT_REFRESH
         end
      end

      def display(force_refresh=false, force_redraw=false, force_layout=false)
         if @want & WANT_LAYOUT > 0  or force_layout
            layout;
            @want ^= WANT_LAYOUT
         end
         return   if not visible?

         if @want & WANT_REDRAW > 0 or force_redraw
            draw
            @want ^= WANT_REDRAW
         end

         if @want > 0 or force_refresh #WANT_REFRESH > 0 or force_refresh
            refresh
            @want ^= WANT_REFRESH
         end
      end

      def want_redraw;  @want |= 3             end
      def want_layout;  @want = 7              end
      def want_refresh; @want |= WANT_REFRESH  end

      def invisible?;  !visible?                                     end
      def visible!;    self.visible=(true)                           end
      def invisible!;  self.visible=(false)                          end
      def visible?;    @visible and (!@parent or @parent.visible?)   end

      def visible=(new)
         return if @visible == new
         with_lock { @visible = new; want_refresh }
      end

      def size=(size)
         return if @size == size
         with_lock { @size = size; want_layout }
      end

      def pos=(pos)
         return if @pos == pos
         with_lock { @pos = pos; want_layout }
      end

      def mouse_event_transform(mevent)
         if mevent.y >= @pos.y and mevent.x >= @pos.x and
               mevent.y < (@pos.y + @size.height) and
               mevent.x < (@pos.x + @size.width)
            new_mouse = mevent.to_fake
            new_mouse.update!(y: mevent.y - @pos.y, x: mevent.x - @pos.x)
            new_mouse
         end
      end

      def key_press(key)        on_key_press(key)         end
      def raise_widget(widget)  on_widget_raise(widget)   end
      def on_key_press(key)     trigger(@keys, key)       end

      def mouse_click(mevent)
         if new_event = mouse_event_transform(mevent)
            trigger(@mouse, new_event)
            trigger(@mouse_event, new_event)
         end
      end

      def draw;     fail NotImplementedError  end
      def refresh;  fail NotImplementedError  end
      def layout;   fail NotImplementedError  end

      protected def trigger(event_obj, event_name, *event_args)
         event_obj.trigger(event_name, *event_args) if event_obj
      end

      def on_widget_raise(widget)
         fail 'unhandled widget raise' unless @parent
         @parent.raise_widget(widget)
      end
   end

   class Window < Widget
      attr_reader :win

      def initialize(**opts)
         super(**opts)
         @win = ICurses.newwin(@size.height, @size.width, @pos.y, @pos.x)
         @win.keypad(true)
         @win.idlok(true)
         @win.leaveok(true)
         @win.bkgdset(UI::Colors.init_pair_cached(:default, :default))
      end

      def layout
         fail WidgetSizeError if @size.height < 1 or @size.width < 1
         @win.size=(@size)
         @win.pos=(@pos)
      end

      def refresh
         @win.refresh
      end

      def noutrefresh
         @win.noutrefresh
      end
   end

   class Pad < Widget
      attr_reader :win

      def initialize(**opts)
         super(**opts)
         @win = ICurses.newpad(@size.height, @size.width)
         @win.keypad(true)
         @win.idlok(true)
         @win.leaveok(true)
         @win.bkgdset(UI::Colors.init_pair_cached(:default, :default))
         @pad_minrow = @pad_mincol = 0
      end

      def pad_minrow=(n)
         return if @pad_minrow == n
         with_lock { @pad_minrow = n; want_refresh }
      end

      def pad_mincol=(n)
         return if @pad_mincol == n
         with_lock { @pad_mincol = n; want_refresh }
      end

      def pad_size=(s)
         @win.size=(s)
      end

      def layout
         @win.pos=(@pos)
      end

      def top;         self.pad_minrow=(0)                 end
      def page_up;     self.up(@size.height / 2)           end
      def page_down;   self.down(@size.height / 2)         end

      def bottom
         self.pad_minrow=(@win.height - @size.height)
      end

      def up(n=1)
         new_minrow = (@pad_minrow - n).clamp(0, @win.height)
         self.pad_minrow=(new_minrow)
      end

      def down(n=1)
         new_minrow = (@pad_minrow + n).clamp(0, (@win.height - @size.height)) rescue 0
         self.pad_minrow=(new_minrow)
      end

      def with_mouse_section_event
         start_cursor = @win.cursor; yield

         start_pos = UI::Point.new(
            y: [start_cursor.y, @win.cursor.y].min,
            x: [start_cursor.x, @win.cursor.x].min,
         )
         stop_pos = UI::Point.new(
            y: [start_cursor.y, @win.cursor.y].max,
            x: [start_cursor.x, @win.cursor.x].max
         )

         ev = UI::MouseSectionEvent.new(start_pos, stop_pos)
         mouse_section.add(ev)
         ev
      end

      def mouse_click(mevent)
         if ev = mouse_event_transform(mevent)
            ev.x += @pad_mincol
            ev.y += @pad_minrow
            trigger(@mouse, ev)
            trigger(@mouse_section, ev)
         end
      end

      def refresh
         @win.prefresh(
            @pad_minrow, @pad_mincol,
            @pos.y, @pos.x,
            @pos.y + @size.height - 1, @pos.x + @size.width - 1
         )
      end

      def noutrefresh
         @win.pnoutrefresh(
            @pad_minrow, @pad_mincol,
            @pos.y, @pos.x,
            @pos.y + @size.height - 1, @pos.x + @size.width - 1
         )
      end
   end
end

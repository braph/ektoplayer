require_relative '../widgets'

module UI
   class GenericContainer < Widget
      attr_reader :selected, :selected_index, :widgets

      def initialize(widgets: [], **opts)
         super(**opts)
         events.register(:changed)
         @selected, @selected_index, @widgets = nil, nil, widgets
      end

      def visible_widgets
         @widgets.select(&:visible?)
      end

      def selected_index=(index)
         return if @selected_index == index

         with_lock do
            if index
               unless @selected = @widgets[index]
                  fail KeyError, "#{self.class}: #{@widgets.size} #{index}"
               end
            end

            @selected_index = index
            trigger(@events, :changed, @selected_index)
            want_layout
         end
      end

      def selected=(widget)
         return if @selected.equal?(widget)

         with_lock do
            if widget
               unless @selected_index = @widgets.index(widget)
                  fail KeyError
               end
            end

            @selected = widget
            trigger(@events, :changed, @selected_index)
            want_layout
         end
      end

      def win
         (@selected or UI::Canvas).win
      end

      def add(widget)
         with_lock do
            @widgets << widget
            self.selected=(widget) unless @selected
            want_layout # important: layout, not redraw
         end
      end

      def remove(widget)
         with_lock do
            self.selected=(nil) if @selected.equal?(widget)
            @widgets.delete widget
            want_layout # important: layout, not redraw
         end
      end

      def mouse_click(mevent)
         visible_widgets.each { |w| w.mouse_click(mevent) }
         super(mevent)
      end

      def draw;     visible_widgets.each(&:draw)     end
      def refresh;  visible_widgets.each(&:refresh)  end
      def layout;   @widgets.each(&:layout)          end

      def on_key_press(key)
         @selected.key_press(key) if @selected
         super(key)
      end

      def select_next
         return unless @selected
         self.selected_index=((@selected_index + 1) % @widgets.size)
      end

      def select_prev
         return unless @selected
         return self.selected_index=(@widgets.size - 1) if @selected_index == 0
         self.selected_index=(@selected_index - 1)
      end
   end

   class HorizontalContainer < GenericContainer
      def layout
         xoff = 0
         visible_widgets.each do |widget|
            widget.with_lock do
               fail WidgetSizeError if xoff + widget.size.width > @size.width
               widget.size=(widget.size.update(height: @size.height))
               widget.pos=(@pos.calc(x: xoff))
               fail WidgetSizeError if widget.size.height > @size.height
               xoff += (widget.size.width + (@pad or 0))
            end
         end

         super
      end
   end

   class VerticalContainer < GenericContainer
      def layout
         yoff = 0
         visible_widgets.each do |widget|
            widget.with_lock do
               widget.size=(widget.size.update(width: @size.width))
               widget.pos=(@pos.calc(y: yoff))
               fail WidgetSizeError if widget.size.width > @size.width
               fail WidgetSizeError if yoff + widget.size.height > @size.height
               yoff += widget.size.height
            end
         end

         super
      end
   end

   class SwitchContainer < GenericContainer
      def layout
         @widgets.each do |widget|
            widget.with_lock do
               widget.size=(@size)
               widget.pos=(@pos)
            end
         end

         super
      end

      def selected=(widget)
         with_lock do
            (@selected.invisible!) if @selected
            super(widget)
            (@selected.visible!) if @selected
            want_layout
         end
      end

      def selected_index=(index)
         with_lock do
            (@selected.invisible!) if @selected
            super(index)
            (@selected.visible!) if @selected
            want_layout
         end
      end
   end
end

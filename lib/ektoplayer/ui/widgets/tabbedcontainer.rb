require_relative 'container'
require_relative 'labelwidget'

module UI
   class TabbedContainer < GenericContainer
      attr_reader :show_tabbar, :attributes

      def initialize(**opts)
         super(**opts)
         @show_tabbar = true
         @tabbar = sub(HorizontalContainer)
         @attributes = Hash.new { 0 }
      end

      def show_tabbar=(new)
         return if @show_tabbar == new
         with_lock { @show_tabbar = new; want_refresh }
      end

      def layout
         if @show_tabbar
            @tabbar.with_lock do
               @tabbar.visible!
               @tabbar.pos=(@pos)
               @tabbar.size=(@size.update(height: 1))
            end

            if @selected
               @selected.with_lock do
                  @selected.size=(@size.calc(height: -1))
                  @selected.pos=(@pos.calc(y: 1))
               end
            end
         else
            if @selected
               @selected.with_lock do
                  @selected.size=(@size)
                  @selected.pos=(@pos)
               end
            end
         end

         super
      end

      def attributes=(new)
         return if @attributes == new
         with_lock { @attributes.update(new); update_tabbar }
      end

      def visible_widgets
         return [@tabbar, @selected] if @show_tabbar and @selected
         return [@selected]          if @selected
         return [@tabbar]            if @show_tabbar
         return []
      end

      def add(widget, title)
         with_lock do
            super(widget)
            tab = @tabbar.sub(LabelWidget, text: title, pad: {left: 1})
            tab.fit
            tab.mouse.on_all { self.selected=(widget) }
            @tabbar.add(tab)
            update_tabbar
         end
      end

      def remove(widget)
         with_lock do
            index = @widgets.index(widget) or fail KeyError
            @tabbar.remove(@tabbar.widgets[index])
            super(widget)
            update_tabbar
         end
      end

      def selected=(widget)
         with_lock do
            (@selected.invisible!) if @selected
            super(widget)
            (@selected.visible!) if @selected
            update_tabbar
            want_layout
         end
      end

      def selected_index=(index)
         with_lock do
            (@selected.invisible!) if @selected
            super(index)
            update_tabbar
            (@selected.visible!) if @selected
            want_layout
         end
      end

      private def update_tabbar
         with_lock do
            @tabbar.widgets.each_with_index do |tab, i|
               if @widgets[i].equal?(@selected)
                  tab.attributes=(@attributes[:'tab_selected'])
               else
                  tab.attributes=(@attributes[:'tabs'])
               end
            end
         end
      end
   end
end

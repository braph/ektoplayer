require_relative '../widgets'

module UI
   class ListItemRenderer
      def initialize(width: nil)
         @width = width
      end

      def width=(new)
         @width != new and (@width = new; layout)
      end

      def layout; end

      def render(scr, item, selected: false, marked: false, selection: false)
         scr << (selected ? ?> : ' ')
         scr << item_to.s
      end
   end

   class ListSelector
      attr_reader :start_pos

      def start(pos)
         @start_pos = pos
      end
      
      def started?; @start_pos end

      def stop(pos)
         return [] unless @start_pos
         r = [pos, @start_pos].min.upto([pos, @start_pos].max).to_a
         @start_pos = nil
         r
      end
   end

   class ListSearch
      attr_accessor :direction

      def initialize(search: '', direction: :down)
         @search, @direction = search, direction
      end

      def search=(search)
         @search = Regexp.new(search.downcase) rescue search.downcase
      end

      private def comp(item)
         if item.is_a?String or item.is_a?Symbol
            return item.downcase =~ @search
         elsif item.is_a?Hash
            %w(title artist album).each do |key|
               return true if comp(item[key])
            end
         end

         false
      end

      def next(*a)  @direction == :up ? search_up(*a) : search_down(*a) end
      def prev(*a)  @direction == :up ? search_down(*a) : search_up(*a) end

      def search_up(current_pos, source)
         start_pos = (current_pos - 1).clamp(0, source.size)

         # search up from current pos to 0
         start_pos.downto(0).each do |i|
            return i if comp(source[i])
         end

         # restart search from bottom to start_pos
         (source.size - 1).downto(start_pos).each do |i|
            return i if comp(source[i])
         end

         nil # not found
      end

      def search_down(current_pos, source)
         start_pos = (current_pos + 1).clamp(0, source.size)

         # search down from current pos
         start_pos.upto(source.size).each do |i|
            return i if comp(source[i])
         end

         # restart search from top to start_pos
         0.upto(start_pos).each do |i|
            return i if comp(source[i])
         end

         nil # not found
      end
   end

   class ListWidget < Window
      attr_reader :list, :selected, :cursor, :selection
      attr_accessor :item_renderer

      def initialize(list: [], item_renderer: nil, **opts)
         super(**opts)
         self.list=(list)
         @item_renderer = (item_renderer or ListItemRenderer.new)
         @cursor = @selected = 0
         @search = ListSearch.new
         @selection = ListSelector.new
      end

      def search_next
         if pos = @search.next(@selected, @list)
            self.selected=(pos)
            self.center
         end
      end

      def search_prev
         if pos = @search.prev(@selected, @list)
            self.selected=(pos)
            self.center
         end
      end

      def search_up;    self.search_start(:up)      end
      def search_down;  self.search_start(:down)    end

      def search_start(direction)
         UI::Input.readline(@pos, @size.update(height: 1), prompt: '> ', add_hist: true) do |result|
            if result
               @search.direction=(direction)
               @search.search=(result)
               search_next
            end
         end
      end

      def toggle_selection
         with_lock do
            if @selection.started?
               @selection.stop(@selected)
               want_redraw
            else
               @selection.start(@selected)
            end
         end
      end

      def get_selection
         self.lock
         r = @selection.stop(@selected)
         r << @selected if r.empty?
         r
      ensure
         want_redraw
         self.unlock
      end

      def render(index, **opts)
         return unless @item_renderer
         return Ektoplayer::Application.log(self, index, caller) unless @list[index]

         opts[:selection] = (@selection.started? and
               index.between?(
                  [@selection.start_pos, @selected].min,
                  [@selection.start_pos, @selected].max
               )
         )

         @item_renderer.render(@win, @list[index], index, **opts)
      end

      def layout
         @item_renderer.width = @size.width if @item_renderer
         super
      end

      def top;         self.selected=(0)                          end
      def bottom;      self.selected=(index_last)                 end
      def page_up;     self.scroll_list_up(@size.height)          end
      def page_down;   self.scroll_list_down(@size.height)        end
      def up(n=1)      self.scroll_cursor_up(1)                   end
      def down(n=1)    self.scroll_cursor_down(1)                 end
      def center;      self.force_cursorpos(@size.height / 2)     end

      def list=(list)
         with_lock do
            @list = list
            @cursor = @selected = 0
            self.selected=(0)
            self.force_cursorpos(0)
            want_redraw
         end
      end

      def scroll_cursor_down(n)
         fail ArgumentError unless n
         fail ArgumentError if n.negative?
         n = n.clamp(0, items_after_cursor)
         return if n == 0
         new_cursor, new_selected = @cursor + n, @selected + n

         self.lock

         # it's faster to redraw the whole screen
         if n >= @size.height
            new_cursor = cursor_max
            want_redraw
         else
            # new cursor resides in current screen
            if new_cursor <= cursor_max
               if @selection.started?
                  want_redraw
               else
                  write_at(@cursor); render(@selected)
                  write_at(new_cursor); render(new_selected, selected: true)
                  want_refresh
               end
            else
               new_cursor = cursor_max

               if @selection.started?
                  want_redraw
               else
                  write_at(@cursor); render(@selected)

                  (index_bottom + 1).upto(new_selected - 1).each do |index|
                     @win.append_bottom; render(index)
                  end

                  @win.append_bottom; render(new_selected, selected: true)

                  want_refresh
               end
            end
         end

         @cursor, @selected = new_cursor, new_selected
      ensure
         self.unlock
      end

      def scroll_cursor_up(n)
         fail ArgumentError unless n
         fail ArgumentError if n.negative?
         n = n.clamp(0, items_before_cursor)
         return if n == 0
         new_cursor, new_selected = @cursor - n, @selected - n

         self.lock

         if n >= @size.height
            new_cursor = 0
            want_redraw
         else
            # new cursor resides in current screen
            if new_cursor >= 0
               if @selection.started?
                  want_redraw
               else
                  write_at(@cursor); render(@selected)
                  write_at(new_cursor); render(new_selected, selected: true)
                  want_refresh
               end
            else
               new_cursor = 0

               if @selection.started?
                  want_redraw
               else
                  write_at(@cursor); render(@selected)

                  (index_top - 1).downto(new_selected + 1).each do |index|
                     @win.insert_top; render(index)
                  end

                  @win.insert_top; render(new_selected, selected: true)

                  want_refresh
               end
            end
         end

         @cursor, @selected = new_cursor, new_selected
      ensure
         self.unlock
      end

      def selected=(new_index)
         fail ArgumentError unless new_index
         fail ArgumentError.new('negative index') if new_index.negative?
         new_index = new_index.clamp(0, index_last)

         with_lock do
            @selected = new_index
            self.force_cursorpos(@cursor)
            want_redraw
         end
      end

      # select an item by its current cursor pos
      def select_from_cursorpos(new_cursor)
         fail unless new_cursor.between?(0, cursor_max)
         return if (new_cursor == @cursor) or @list.empty?

         with_lock do
            old_cursor, @cursor = @cursor, new_cursor
            old_selected, @selected = @selected, (@selected - (old_cursor - @cursor)).clamp(0, index_last)

            if @selection.started?
               want_redraw
            else
               write_at(old_cursor); render(old_selected)
               write_at(new_cursor); render(@selected, selected: true)
               want_refresh
            end
         end
      end

      def force_cursorpos(new_cursor)
         with_lock do
            if @selected <= cursor_max / 2
               @cursor = @selected
            elsif (diff = (index_last - @selected)) < cursor_max / 2
               @cursor = @size.height - diff - 1
            else
               @cursor = new_cursor.clamp(cursor_max / 2, cursor_max)
            end

            want_redraw
         end
      end

      def scroll_list_up(n=1)
         fail ArgumentError unless n
         n = n.clamp(0, items_before_cursor)
         return if n == 0 or @list.empty?
         self.lock

         if index_top == 0
            # list is already on top
            select_from_cursorpos((@cursor - n).clamp(0, cursor_max))
         elsif n < @size.height
            old_index_top = index_top
            old_selected, @selected = @selected, @selected - n

            if lines_after_cursor > n
               write_at(@cursor); render(old_selected) 
            end

            (old_index_top - 1).downto(old_index_top - n).each do |index|
               @win.insert_top; render(index)
            end

            write_at(@cursor); render(@selected, selected: true)

            want_refresh
         else
            @selected -= n
            force_cursorpos(@cursor)
            want_redraw
         end

         self.unlock
      end

      def scroll_list_down(n=1)
         fail ArgumentError unless n
         n = n.clamp(0, items_after_cursor)
         return if n == 0 or @list.empty?
         self.lock

         if index_bottom == index_last
            select_from_cursorpos((@cursor + n).clamp(0, cursor_max))
         elsif n < @size.height
            old_index_bottom = index_bottom
            old_selected, @selected = @selected, @selected + n

            if lines_before_cursor > n
               write_at(@cursor); render(old_selected)
            end

            (old_index_bottom + 1).upto(old_index_bottom + n).each do |index|
               @win.append_bottom; render(index)
            end

            write_at(@cursor); render(@selected, selected: true)

            want_refresh
         else
            @selected += n
            force_cursorpos(@cursor)
            want_redraw
         end

         self.unlock
      end

      def draw
         @win.erase
         return if @list.empty?
         #@selected = @selected.clamp(0, index_last)

         @cursor.times do |i|
            unless @list[@selected - (@cursor - i)]
               @cursor = i
               break
            end

            write_at(i); render(@selected - (@cursor - i))
         end

         write_at(@cursor); render(@selected, selected: true)

         (@cursor + 1).upto(@size.height - 1).each_with_index do |c, i|
            break unless @list[@selected + i + 1]
            write_at(c); render(@selected + i + 1)
         end
      end

      def on_mouse_click(mevent, mevent_transformed)
         if new_mouse = mouse_event_transform(mevent)
            select_from_cursorpos(new_mouse.y)
         end
         super(mevent)
      end

      protected

      def write_at(pos)   @win.move(pos, 0)               end

      def index_first;   0                                end
      def index_last;    [@list.size, 1].max - 1          end
      def index_top;     @selected - @cursor              end
      def index_bottom
         [@selected + @size.height - @cursor, @list.size].min - 1
      end

      def lines_before_cursor;  @cursor                      end
      def lines_after_cursor;   @size.height - cursor - 1    end
      def items_before_cursor;  @selected;                   end
      def items_after_cursor;   @list.size - @selected - 1   end
      def cursor_min;    0                                   end
      def cursor_max
         @list.empty? ? 0 : [@list.size, @size.height].min - 1
      end
   end
end

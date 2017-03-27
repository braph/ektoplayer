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
      attr_accessor :direction, :search

      def initialize(search: '', direction: :down)
         @search, @direction = search, direction
      end

      def comp(item, search)
         if item.is_a?String or item.is_a?Symbol
            return item.downcase =~ Regexp.new(search.downcase)
         elsif item.is_a?Hash
            %w(title artist album).each do |key|
               return true if self.comp(item[key], search)
            end
         end

         false
      end

      def next(*a)  @direction == :up ? search_up(*a): search_down(*a)  end
      def prev(*a)  @direction == :up ? search_down(*a) : search_up(*a) end

      def search_up(current_pos, source)
         start_pos = (current_pos - 1).clamp(0, source.size)

         start_pos.downto(0).each do |i|
            return i if self.comp(source[i], @search)
         end

         source.size
      end

      def search_down(current_pos, source)
         start_pos = (current_pos + 1).clamp(0, source.size)

         start_pos.upto(source.size).each do |i|
            return i if self.comp(source[i], @search)
         end

         0
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

      def search_next;  self.selected=(@search.next(@selected, @list))  end
      def search_prev;  self.selected=(@search.prev(@selected, @list))  end
      def search_up;    self.search_start(:up)                          end
      def search_down;  self.search_start(:down)                        end
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
         return Ektoplayer::Application.log(self, 'render todo') unless @list[index]

         opts[:selection] = (@selection.started? and (
               opts[:selected] or index.between?(
                  [@selection.start_pos, @selected].min,
                  [@selection.start_pos, @selected].max
               )
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
      def page_up;     self.scroll_up(size.height)                end
      def page_down;   self.scroll_down(size.height)              end
      def up(n=1)      self.selected=(selected - n)               end
      def down(n=1)    self.selected=(selected + n)               end
      def center;      self.force_cursorpos(@size.height / 2)     end

      def list=(list)
         with_lock do
            @list = list
            @cursor = @selected = 0
            self.selected=(0)
            want_redraw
         end
      end

      def selected=(new_index)
         fail ArgumentError unless new_index
         old_index_bottom = index_bottom
         old_index_top = index_top
         old_selected, @selected = @selected, new_index.clamp(0, index_last)
         return if old_selected == @selected or @list.empty?

         self.lock

         old_cursor, new_cursor = @cursor, @cursor + @selected - old_selected

         if new_cursor.between?(0, @size.height - 1)
            # new selected item resides in current screen,
            # just want_redraw the old line and the newly selected one
            @cursor = new_cursor

            # redraw whole screen in selection mode!
            return want_redraw if @selection.started?

            write_at(old_cursor); render(old_selected)
            write_at(new_cursor); render(new_index, selected: true)
            _check
            want_refresh
         elsif (new_cursor.between?(-(@size.height - 1), (2 * @size.height - 1)))
            # new selected item is max a half screen size away
            if @selected < old_selected
               if lines_after_cursor > (old_selected - @selected)
                  write_at(old_cursor); render(old_selected)
               end

               (old_index_top - 1).downto(@selected + 1).each do |index|
                  @win.insert_top; render(index)
               end

               @win.insert_top; render(@selected, selected: true)
               @cursor = 0
               _check
            else
               if lines_before_cursor > (@selected - old_selected)
                  write_at(old_cursor); render(old_selected)
               end

               (old_index_bottom + 1).upto(@selected - 1).each do |index|
                  @win.append_bottom; render(index)
               end

               @win.append_bottom; render(@selected, selected: true)
               @cursor = cursor_max
               _check
            end

            want_refresh
         else
            #@selected = new_index
            @cursor = new_index.clamp(0, cursor_max) # todo new_index<>new_cursor? ne muess scho pasn
            _check
            want_redraw
         end

      ensure
         self.unlock
      end

      # select an item by its current cursor pos
      def select_from_cursorpos(new_cursor)
         fail unless new_cursor.between?(0, cursor_max)
         # FIXME: clamp with @list.size ????
         return if (new_cursor == @cursor) or @list.empty?

         with_lock do
            old_cursor, @cursor = @cursor, new_cursor
            old_selected, @selected = @selected, (@selected - (old_cursor - @cursor)).clamp(0, index_last)
            _check

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
         self.lock
         if @selected <= cursor_max
            @cursor = @selected
         elsif (diff = (index_last - @selected)) < cursor_max
            @cursor = @size.height - diff - 1  #cursor_max.clamp(0, index_last - @selected)
         else
            @cursor = new_cursor.clamp(0, cursor_max)
         end
         want_redraw
         self.unlock
      end

      def scroll_up(n=1)
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

            _check
            want_refresh
         else
            @selected -= n # TODO: move up?
            force_cursorpos(@cursor)
            _check # todo: move up
            want_redraw
         end

         self.unlock
      end

      def scroll_down(n=1)
         fail ArgumentError unless n
         n = n.clamp(0, items_after_cursor)
         return if n == 0 or @list.empty?
         self.lock

         if index_bottom == index_last
            select_from_cursorpos((@cursor + n).clamp(0, cursor_max))
            _check
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

            _check
            want_refresh
         else
            @selected += n
            force_cursorpos(@cursor)
            _check
            want_redraw
         end

         self.unlock
         _check
      end

      def draw
         @win.erase
         return if @list.empty?
         @selected = @selected.clamp(0, index_last)
         _check

         @cursor.times do |i|
            unless row = @list[@selected - (@cursor - i)]
               @cursor = i
               break
            end

            write_at(i); render(@selected - (@cursor - i))
         end

         _check
         write_at(@cursor); render(@selected, selected: true)

         (@cursor + 1).upto(@size.height - 1).each_with_index do |c, i|
            break unless row = @list[@selected + i + 1]
            write_at(c); render(@selected + i + 1)
         end

         _check
      end

      def on_mouse_click(mevent, mevent_transformed)
         if new_mouse = mouse_event_transform(mevent)
            select_from_cursorpos(new_mouse.y)
         end
         super(mevent)
      end

      protected

      def write_at(pos)   @win.line_start(pos).clrtoeol   end

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
      def cursor_max;    [@size.height, @list.size].min - 1  end

      private def _check # debug method
         return
         fail "@selected = nil"           unless @selected
         fail "@selected = #{@selected}"  unless @selected >= 0
         fail "@selected > @list.size"    if @selected >= @list.size
         fail "@cursor = nil"             unless @cursor
         fail "@cursor = #{@cursor}"      unless @cursor >= 0
         fail "@cursor > max"             if @cursor > @win.maxy
      end
   end
end

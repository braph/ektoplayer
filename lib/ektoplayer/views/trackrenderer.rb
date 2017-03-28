require_relative '../ui/widgets'

class PercentualDistributor
   def initialize(total: 0, parts: [])
      @total, @parts = total, parts
      @results = nil
   end

   def increment_total(n)
      @total += n
      @results = nil
   end
   
   def add_part(n)
      @parts << n
      @results = nil
   end

   def get_for(part)
      fail ArgumentError unless @parts.include? part

      unless @results
         @results = Hash.new { |h,k| h[k] = [] }

         part_total, results_total = @parts.sum, 0
         @parts.each_with_index do |p,i|
            v = @total * p / part_total
            @results[p] << v
            results_total += v
         end

         @results.each do |k, values|
            values.map! do |v|
               if results_total > @total
                  results_total -= 1
                  v - 1
               elsif results_total < @total
                  results_total += 1
                  v + 1
               else
                  v
               end
            end
         end
      end

      @results[part].unshift(r = @results[part].pop)
      r
   end
end

module Ektoplayer
   module Views
      class TrackRenderer < UI::ListItemRenderer
         def initialize(width: nil, format: nil)
            super(width: width)
            self.column_format=(format)
         end

         def column_format=(format)
            return unless format
            @column_format = format
            layout
         end

         def layout
            return unless @column_format
            fail if @column_format.empty?
            fail unless @width

            pd = PercentualDistributor.new(
               total: (@width - (@column_format.size - 1))
            )

            @column_format.each do |c|
               if c[:rel]
                  pd.add_part(c[:rel])
               else
                  c[:render_size] = c[:size]
                  pd.increment_total(-1 * c[:size])
               end

               c[:curses_codes] = UI::Colors.set(nil, *c[:curses_attrs])
            end

            @column_format.each do |c|
               if c[:rel]
                  c[:render_size] = (pd.get_for(c[:rel]) or fail)
               end
            end
         end

         def render(scr, item, index, selected: false, marked: false, selection: false)
            fail ArgumentError, 'item is nil' unless item
            return unless @column_format

            additional_attributes = 0
            additional_attributes |= ICurses::A_BOLD     if marked
            additional_attributes |= ICurses::A_STANDOUT if selected

            if item.is_a? String or item.is_a? Symbol or item.is_a? Integer
               if selection
                  color = Theme[:'list.item_selection']
               elsif index % 2 == 0
                  color = Theme[:'list.item_even']
               else
                  color = Theme[:'list.item_odd']
               end

               scr.attrset(color | additional_attributes)
               scr.addstr("[#{item}]".ljust(@width))
               return
            end

            left_pad = 0
            y = scr.cury

            @column_format.each_with_index do |c,i|
               if selection
                  scr.attrset(Theme[:'list.item_selection'] | additional_attributes)
               else
                  scr.attrset(c[:curses_codes] | additional_attributes)
               end

               if value = item[c[:tag]]
                  if value.is_a? Integer
                     value = '%.2d' % value
                  else
                     value = value.to_s[0..(c[:render_size] - 1)]
                  end

                  scr.mvaddstr(y, left_pad, ' ' * c[:render_size])
                  scr.addch(32) if i < @column_format.size - 1

                  if c[:justify] == :right
                     scr.mvaddstr(y, left_pad, value.rjust(c[:render_size]))
                  else
                     scr.mvaddstr(y, left_pad, value)
                  end
               end

               left_pad += c[:render_size] + 1
            end
         end
      end 
   end
end

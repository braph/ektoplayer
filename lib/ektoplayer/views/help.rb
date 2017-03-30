require_relative '../ui/widgets'
require_relative '../bindings'
require_relative '../theme'

module Ektoplayer
   module Views
      class Help < UI::Pad
         def draw;
         end

         def layout
            self.pad_size=(UI::Size.new(
               height: (Bindings.bindings.values.map(&:size).sum +
                        Bindings.bindings.size * 2),
               width:  [@size.width, 90].max
            ))

            @win.erase

            Bindings.bindings.each do |widget, commands|
               @win.attrset(Theme[:'help.widget_name'])
               @win.addstr("\n#{widget}\n")

               commands.each do |name, keys|
                  next if keys.empty?

                  @win.on_column(3)
                  keys.map { |k| Bindings.keyname(k) }.
                     sort.each_with_index do |key,i|
                     @win << ', ' if i > 0
                     @win.with_attr(Theme[:'help.key_name']) { @win << key }
                  end

                  @win.attrset(Theme[:'help.command_name'])
                  @win.mvaddstr(@win.cury, 18, name.to_s)

                  @win.attrset(Theme[:'help.command_desc'])
                  @win.mvaddstr(@win.cury, 45, Bindings.commands[name.to_sym])

                  @win.next_line
               end
            end
         end
      end
   end
end

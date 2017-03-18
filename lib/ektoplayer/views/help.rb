require_relative '../ui/widgets'
require_relative '../bindings'
require_relative '../theme'

module Ektoplayer
   module Views
      class Help < UI::Pad
         def draw
            self.pad_size=(UI::Size.new(
               height: (Bindings.bindings.values.map(&:size).sum +
                        Bindings.bindings.size * 2),
               width:  [@size.width, 90].max
            ))

            @win.erase

            Bindings.bindings.each do |widget, commands|
               @win.with_attr(Theme[:'help.widget_name']) do
                  @win << "\n#{widget}\n"
               end

               commands.each do |name, keys|
                  next if keys.empty?

                  @win.on_column(3)
                  keys.map { |k| Bindings.keyname(k) }.
                     sort.each_with_index do |key,i|
                     @win << ', ' if i > 0
                     @win.with_attr(Theme[:'help.key_name']) { @win << key }
                  end

                  @win.with_attr(Theme[:'help.command_name']) do
                     @win.on_column(18).addstr("#{name}")
                  end

                  @win.with_attr(Theme[:'help.command_desc']) do
                     @win.on_column(43).addstr(Bindings.commands[name.to_sym])
                  end

                  @win.addch(?\n)
               end
            end
         end
      end
   end
end

require_relative 'controller'
require_relative '../bindings'

module Ektoplayer
   module Controllers
      class Playlist < Controller
         def initialize(view, playlist, view_operations, operations)
            super(view)
            view.attach(playlist)

            register = view_operations.with_register('playlist.')
            %w(up down page_up page_down top bottom
               search_up search_down search_next search_prev toggle_selection).
               each { |op| register.(op, &@view.method(op)) }

            register.(:play) do
               operations.send(:'playlist.play', view.selected)
            end

            register.(:reload) do
               view.get_selection.each do |index|
                  operations.send(:'playlist.reload', index)
               end
            end

            register.(:download_album) do
               view.get_selection.each do |index|
                  operations.send(:'playlist.download_album', index)
               end
            end

            register.(:delete) do
               view.with_lock do
                  old_cursor, selection = view.cursor, view.get_selection

                  selection.each do 
                     operations.send(:'playlist.delete', selection[0])
                  end

                  view.selected=(selection[0])
                  view.force_cursorpos(old_cursor)
               end
            end

            register.(:goto_current) do
               view.with_lock do
                  if index = playlist.current_playing
                     view.selected=(index)
                     view.center()
                  end
               end
            end

            # TODO: mouse?
            view.mouse.on(65536) do view.up(5) end
            view.mouse.on(2097152) do view.down(5) end

            [Curses::BUTTON1_CLICKED, Curses::BUTTON2_CLICKED].
               each do |button|
               view.mouse.on(button) do |mevent|
                  view.select_from_cursorpos(mevent.y)
               end
            end

            [Curses::BUTTON1_DOUBLE_CLICKED, Curses::BUTTON3_CLICKED].each do |btn|
               view.mouse.on(btn) do |mevent|
                  view.select_from_cursorpos(mevent.y)
                  view_operations.send('playlist.play')
               end
            end
         end
      end
   end
end

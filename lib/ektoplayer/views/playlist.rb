require_relative '../ui/widgets/listwidget'
require_relative '../config'

require_relative 'trackrenderer'

module Ektoplayer
   module Views
      class Playlist < UI::ListWidget
         def initialize(**opts)
            super(**opts)

            if ICurses.colors == 256
               f = Config[:'playlist.format_256']
            else
               f = Config[:'playlist.format']
            end

            self.item_renderer=(TrackRenderer.new(width: @size.width, format: f))
         end
         
         def attach(playlist)
            self.list=(playlist.to_a)

            playlist.events.on(:changed) do
               with_lock { self.list=(playlist.to_a); want_redraw }
            end

            playlist.events.on(:current_changed) do
               self.current_playing=(playlist.current_playing)
            end
         end

         def render(index, **opts)
            opts[:marked] = true if index == @current_playing
            super(index, **opts)
         end

         def current_playing=(p)
            return if @current_playing == p
            with_lock { @current_playing = p; want_redraw }
         end
      end
   end
end

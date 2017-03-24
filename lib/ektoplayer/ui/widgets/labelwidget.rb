require_relative '../widgets'

module UI
   class LabelWidget < Window
      attr_reader :text, :pad, :attributes

      def initialize(text: '', attributes: 0, pad: {}, **opts)
         super(**opts)
         @text, @attributes, @pad = text.to_s, attributes, Hash.new(0)
         @pad.update pad
      end

      def attributes=(new)
         return if @attributes == new
         with_lock { @attributes = new; want_redraw }
      end

      def text=(new)
         return if @text == new
         with_lock { @text = new.to_s; want_redraw }
      end

      def pad=(new)
         return if @pad == new
         with_lock { @pad.update!(new); want_redraw }
      end

      def draw
         @win.erase
         @text.split(?\n).each_with_index do |l, i|
            @win.move(@pad[:top] + i, @pad[:left])
            @win.attron(@attributes) { @win << l }
         end
      end

      def fit
         self.size=(Size.new(
            height: @pad[:top] + @pad[:bottom] + 1 + @text.count(?\n),
            width:  @pad[:left] + @pad[:right] + @text.split(?\n).max.size
         ))

         self
      end
   end
end

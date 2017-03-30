require_relative '../ui/colors'
require_relative '../ui/widgets'
require_relative '../theme'
require_relative '../common'

module Ektoplayer
   module Views
      class Splash < UI::Window
         EKTOPLAZM_LOGO = %q.
   ____    _   _     _             ____    _       _____   ______   _ ___ ___
  /  __)  ; | | ;   | |           |  _ \  | |     /___  \ |____  | | '_  `_  \
 /  /     | | | |  _| |__   ___   | | | | | |         | |      | | | | | | | |
(  (      | | | | |_   __) / _ \  | | | | | |      ___| |      / , | | | | | |
 \  \_    | | | |   | |   | | | | | | | | | |     /  _| |     / /  | | | | | |
  )  _)   | | | |   | |   | | | | | |_| ; | |     | | | |    / /   | | | | | |
 /  /     | |_|/    | |   | |_| | |  __/  | |     | | | |   / /    | | | | | |
(  (      |  _{     | |    \___/  | |     | |     | | | |  / /     | | |_| | |
 \  \__   | | |\    | |__         | |     | :___  | |_| | , /____  | |     | |
  \____)  |_| |_|   \___/         |_|     \____/  \_____| |______| |_|     |_|..
                                                       split(?\n)[1..-1].freeze
         EKTOPLAZM_SIGNATURE = %q{
  ___                   _   _    _ _                  _   _
 / __| ___ _  _ _ _  __| | | |  (_) |__  ___ _ _ __ _| |_(_)___ _ _
 \__ \/ _ \ || | ' \/ _` | | |__| | '_ \/ -_) '_/ _` |  _| / _ \ ' \
 |___/\___/\_,_|_||_\__,_| |____|_|_.__/\___|_| \__,_|\__|_\___/_||_|}.
                                                       split(?\n)[1..-1].freeze

         BUBBLES = [[6,3], [6,7], [28,1], [28,9], [46,7], [71,9]].freeze

         def load_colors
            if Theme.current == 256
               @bubble_fade    = UI::ColorFader.new([168,167,161,161,161])
               @signature_fade = UI::ColorFader.new([99, 105, 111, 117])
               @ekto_logo_fade = UI::ColorFader.new([23, 23, 29, 36, 42, 48, 42, 36, 29, 23])
            elsif Theme.current == 8
               @bubble_fade    = UI::ColorFader.new([:red])
               @ekto_logo_fade = UI::ColorFader.new([:blue])
               @signature_fade = UI::ColorFader.new([:magenta])
            else
               @bubble_fade = @signature_fade = @ekto_logo_fade = UI::ColorFader.new([-1])
            end
         end

         def draw
            @win.erase
            return if (EKTOPLAZM_LOGO.size >= @size.height or
                      EKTOPLAZM_LOGO.max.size >= @size.width)
            load_colors

            w_center = @size.width / 2
            h_center = @size.height / 2
            left_pad = w_center - (EKTOPLAZM_LOGO.max.size / 2)

            if EKTOPLAZM_LOGO.size + EKTOPLAZM_SIGNATURE.size + 3 > @size.height
               top_pad = h_center - (EKTOPLAZM_LOGO.size / 2)
               draw_signature = false 
            else
               top_pad = h_center - (EKTOPLAZM_LOGO.size / 2 + 3)
               draw_signature = true
            end

            @ekto_logo_fade.fade(EKTOPLAZM_LOGO.size).each_with_index do |c,i|
               @win.attrset(c)
               @win.mvaddstr(top_pad + i, left_pad, EKTOPLAZM_LOGO[i])
            end

            f = @bubble_fade.fade(EKTOPLAZM_LOGO.size)
            BUBBLES.each do |x,y|
               @win.attrset(f[y - 1])
               @win.mvaddstr(top_pad + y - 1, left_pad + x + 1, ?_)
               @win.attrset(f[y])
               @win.mvaddstr(top_pad + y, left_pad + x, '(_)')
            end

            return unless draw_signature

            top_pad += EKTOPLAZM_LOGO.size + 2
            left_pad = w_center - (EKTOPLAZM_SIGNATURE.max.size / 2)

            EKTOPLAZM_SIGNATURE.each_with_index do |line, i|
               @win.move(top_pad + i, left_pad)
               @signature_fade.fade2(line.size).each_with_index do |color,y|
                  @win.attrset(color)
                  @win.addstr(line[y])
               end
            end
         end
      end
   end
end

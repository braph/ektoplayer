%w(ffi-ncurses ncursesw ncurses curses).each do |f|
   begin
      $USING_CURSES = f
      require_relative "icurses/#{f}" 
      break
   rescue LoadError
      $USING_CURSES = nil
   end
end

fail %{
No interface for ncurses found. Please install one of the following gems
   - curses
   - ffi-ncurses
   - ncurses-ruby
   - ncursesw

Maybe your distribution ships one of these already as a package.
} unless $USING_CURSES

require_relative 'icurses/sugar'

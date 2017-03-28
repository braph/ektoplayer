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
No module for ncurses found. Please install one of the following gems:
   - ffi-ncurses  (preferred)
   - ncursesw     (good)
   - ncurses-ruby (good) 
   - curses       (works...)

Maybe your distribution ships one of these already as a package.

   Arch Linux:
      yaourt -S ruby-curses    # or
      yaourt -S ruby-ncursesw

   Debian / Ubuntu:
      apt-get install ruby-ncurses

} unless $USING_CURSES

require_relative 'icurses/sugar'

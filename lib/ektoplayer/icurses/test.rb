#!/bin/ruby

unless ARGV[0]
   %w(curses ncurses ncursesw ffi_curses).each do |i|
      puts i
      fail i unless 0 == system($0, i)
   end
   exit
end

require_relative ARGV[0]

begin
   ICurses.initscr
   ICurses.mousemask(ICurses::ALL_MOUSE_EVENTS, [])

   w = ICurses.newwin(0,0,0,0)
   w.erase; w.clear

   w.addstr(ARGV[0])
   w.mvaddstr(1,0, 'test 1')
   w.move(2,0);
   w.addstr('test 2')
   x, y = w.getcurx, w.getcury
   w.mvaddstr(y + 1, 0, 'test 3')
   w.addstr("my term is #{ICurses.LINES} lines and #{ICurses.COLS} cols")
   w.resize(50, 30)
   w.noutrefresh
   w.refresh
   w.keypad(true)
   w.timeout(-1)
   w.nodelay(false)
   w.notimeout(true)
   ICurses.curs_set(1); ICurses.curs_set(0)
   ICurses.nl; ICurses.nonl
   ICurses.noecho; ICurses.noecho

   # === Colors === #
   ICurses.start_color
   ICurses.use_default_colors
   ICurses.init_pair(1, ICurses::COLOR_BLACK, ICurses::COLOR_GREEN)
   w.attron(ICurses.color_pair(1))
   w.addstr("my term is has #{ICurses.COLORS}")

   # === Sugar === 
   w << 'sugar'

   loop do
      c = w.getch
      ch = c.chr rescue ''
      w.addstr("#{ch}")
      break if ch == ?q
   end
ensure
   ICurses.endwin rescue puts $!
end


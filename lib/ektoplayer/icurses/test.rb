#!/usr/bin/env ruby

unless ARGV[0]
   %w(curses ncurses ncursesw ffi-curses).each do |i|
      puts i
      fail i unless system($0, i)
   end
   exit
end

$USING_CURSES = ARGV[0]
require_relative ARGV[0]
require_relative 'sugar'

begin
   warn 'call: initscr'
   ICurses.initscr

   warn 'call: stdscr'
   s = ICurses.stdscr
   warn 'call: stdscr.clear, stdscr.refresh'
   s.clear; s.refresh

   warn 'call: newwin(0,0,0,0)'
   w = ICurses.newwin(0,0,0,0)
   warn 'call: win.erase'
   w.erase

   warn 'call: win.addstr, win.mvaddstr, win.move, win.getcurx, win.getcury'
   w.addstr(ARGV[0])
   w.mvaddstr(1,0, 'test 1')
   w.move(2,0);
   w.addstr('test 2')
   x, y = w.getcurx, w.getcury
   w.mvaddstr(y + 1, 0, 'test 3')

   warn 'call win.getch'
   w.getch

   warn 'call: LINES COLS'
   w.addstr("my term is #{ICurses.LINES} lines and #{ICurses.COLS} cols")

   warn 'call: win.resize'
   w.resize(50, 30)

   warn 'call: win.refresh, win.noutrefresh'
   w.refresh; w.noutrefresh

   warn 'call: keypad(true)'
   w.keypad(true)

   warn 'call: timeout(-1)'
   w.timeout(1000)

   warn 'call: nodelay(false)'
   w.nodelay(false)

   warn 'call: notimeout(true)'
   w.notimeout(true)

   warn 'call: curs_set, nl, nonl, echo, noecho'
   ICurses.curs_set(1); ICurses.curs_set(0)
   ICurses.nl; ICurses.nonl
   ICurses.echo; ICurses.noecho

   warn 'call: mousemask'
   ICurses.mousemask(ICurses::ALL_MOUSE_EVENTS, [])

   # === Colors === #
   warn 'call: start_color, use_default_colors, init_pair, attron, attroff'
   ICurses.start_color
   ICurses.use_default_colors
   ICurses.init_pair(1, ICurses::COLOR_BLACK, ICurses::COLOR_GREEN)
   w.attron(ICurses.color_pair(1))
   w.addstr("my term is has #{ICurses.COLORS}")
   w.attroff(ICurses.color_pair(1))

   # === Sugar === 
   warn 'call: <<'
   w << 'sugar'

   loop do
      sleep 0.1
      warn 'call getch()'
      c = w.getch
      unless c
         warn "empty getch"
         next
      end
      warn "returned #{c} (#{c.ord})"
      ch = c.chr rescue ''
      w.addstr("#{ch}")
      break if ch == ?q
   end
ensure
   ICurses.endwin rescue puts $!
end

exit 0

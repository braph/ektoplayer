require_relative 'icurses'
require 'readline'
require 'io/console'

require_relative 'ui/colors'
require_relative 'events'

module UI
   class WidgetSizeError < Exception; end

   class Canvas
      extend ICurses

      def self.size
         UI::Size.new(height: ICurses.lines, width: ICurses.cols)
      end

      def self.cursor
         #UI::Point.new(y: ICurses.cury, x: ICurses.curx)
      end

      def self.pos
         UI::Point.new
      end

      def self.start
         @@widget = nil

         %w(initscr cbreak noecho start_color use_default_colors).
            each(&ICurses.method(:send))
         ICurses.mousemask(ICurses::ALL_MOUSE_EVENTS | ICurses::REPORT_MOUSE_POSITION)
         ICurses.stdscr.keypad(true)
         UI::Colors.start

         self.enable_resize_detection
      end

      def self.enable_resize_detection
         Signal.trap('WINCH') { @@want_resize = true }
      end

      def self.widget;      @@widget                   end
      def self.widget=(w)   @@widget = w               end
      def self.stop;        ICurses.endwin             end
      def self.visible?;    true                       end
      def self.inivsibile?; false                      end

      def self.sub(cls, **opts)
         @@widget ||= (widget = cls.new(parent: self, **opts))
         widget
      end

      def self.update_screen(force_redraw=false, force_resize=false)
         @@updating ||= Mutex.new
         @@want_resize ||= false

         if @@updating.try_lock
            begin
               if @@want_resize or force_resize
                  @@want_resize = false
                  h, w = IO.console.winsize()
                  ICurses.resizeterm(h, w)
                  @@widget.size=(Size.new(height: h, width: w)) if @@widget
                  @@widget.display(true, true, true) if @@widget
               else
                  @@widget.display(true, force_redraw) if @@widget
               end
            rescue UI::WidgetSizeError
               ICurses.stdscr.clear
               ICurses.stdscr.addstr('terminal too small!')
            rescue
               Ektoplayer::Application.log(self, $!)
            end

            @@updating.unlock
         end
      end

      def self.run
         self.start
         return yield
      ensure
         self.stop
      end
   end

   class Input
      KEYMAP_WORKAROUND = {
         13  => ICurses::KEY_ENTER,
         127 => ICurses::KEY_BACKSPACE
      }
      KEYMAP_WORKAROUND.default_proc = proc { |h,k| k }
      KEYMAP_WORKAROUND.freeze

      def self.start_loop
         @@readline_obj ||= ReadlineWindow.new

         loop do
            unless @@readline_obj.active?
               ICurses.curs_set(0)
               ICurses.nonl

               begin
                  UI::Canvas.widget.win.keypad(true)

                  if (c = (UI::Canvas.widget.win.getch1(500).ord rescue -1)) > -1
                     if c == ICurses::KEY_MOUSE
                        if c = ICurses.getmouse
                           UI::Canvas.widget.mouse_click(c)
                        end
                     else
                        UI::Canvas.widget.key_press(KEYMAP_WORKAROUND[c])
                     end
                  end

                  ICurses.doupdate
               end while !@@readline_obj.active?
            else
               ICurses.curs_set(1)
               ICurses.nl

               begin
                  win = UI::Canvas.widget.win
                  win.keypad(false)
                  @@readline_obj.redraw
                  next unless (c = (win.getch1(100).ord rescue -1)) > -1

                  if c == 10 or c == 4
                     @@readline_obj.feed(?\n.ord)
                  else
                     @@readline_obj.feed(c)

                     if c == 27 # pass 3-character escape sequence
                        win.timeout(5)
                        if (c = (win.getch.ord rescue -1)) > -1
                           @@readline_obj.feed(c)
                           if (c = (win.getch.ord rescue -1)) > -1
                              @@readline_obj.feed(c)
                           end
                        end
                     end
                  end
               end while @@readline_obj.active?
            end
         end
      end

      def self.readline(*args, **opts, &block)
         (@@readline_obj ||= ReadlineWindow.new).readline(*args, **opts) do |result|
            Canvas.class_variable_get('@@updating').synchronize { yield result }
         end
      end
   end

   class ReadlineWindow
      def initialize
         Readline.input, @readline_in_write = IO.pipe
         Readline.output = File.open(File::NULL, ?w)
         @window = ICurses.newwin(0,0,0,0)
         @thread = nil
      end

      def active?; @thread; end

      def redraw
         @window.resize(@size.height, @size.width)
         @window.mvwin(@pos.y, @pos.x)
         @window.erase
         buffer = @prompt + Readline.line_buffer.to_s
         @window.addstr(buffer[(buffer.size - @size.width).clamp(0, buffer.size)..-1])
         @window.move(0, Readline.point + @prompt.size)
         @window.refresh
      rescue
         nil
      end

      def readline(pos, size, prompt: '', add_hist: false, &block)
         @thread ||= Thread.new do
            @size, @pos, @prompt = size, pos, prompt

            begin
               Readline.set_screen_size(size.height, size.width)
               Readline.delete_text
               @readline_in_write.read_nonblock(100) rescue nil
               block.(Readline.readline(prompt, add_hist))
            ensure
               @window.clear
               @thread = nil
               UI::Canvas.update_screen(true)
            end
         end
      end

      def feed(c)
         @readline_in_write.putc(c)
         Thread.pass
         @thread = nil if c == ?\n.ord
         redraw
      end
   end

   class Output
      def self.error
         fail NotImplementedError
      end
   end

   class Point
      attr_accessor :x, :y

      def initialize(x: 0, y: 0)
         @x, @y = x, y
      end

      def update(x: nil, y: nil)
         Point.new(x: (x or @x), y: (y or @y))
      end

      def calc(x: 0, y: 0)
         Point.new(x: @x + x, y: @y + y)
      end

      def >=(p)  @x >= p.x and @y >= p.y     end
      def <=(p)  @x <= p.x and @y <= p.y     end
      def ==(p)  @x == p.x and @y == p.y     end
      def to_s;  "[(Point) x=#{x}, y=#{y}]"  end
   end

   class Size
      attr_accessor :width, :height

      def initialize(width: 0, height: 0)
         @width, @height = width, height
      end

      def update(width: nil, height: nil)
         Size.new(width: (width or @width), height: (height or @height))
      end

      def calc(height: 0, width: 0)
         Size.new(height: @height + height, width: @width + width)
      end

      def ==(s)  s.height == @height and s.width == @width    end
      def to_s;  "[(Size) height=#{height}, width=#{width}]"  end
   end
   
   class MouseEvents < Events
      def on(mouse_event, &block)
         return on_all(&block) if mouse_event == ICurses::ALL_MOUSE_EVENTS
         super(mouse_event, &block)
      end

      def trigger(mouse_event)
         super(mouse_event.bstate, mouse_event)
      end
   end

   class MouseSectionEvents
      def initialize
         @events = []
      end

      def clear
         @events.clear
      end

      def add(mouse_section_event)
         @events << mouse_section_event
      end

      def trigger(mevent)
         @events.each { |e| e.trigger(mevent) }
      end
   end

   class MouseSectionEvent
      def initialize(start=nil, stop=nil)
         @start_pos, @stop_pos, @events = start, stop, MouseEvents.new
      end

      def on(button, &block); @events.on(button, &block)  end

      def trigger(mevent)
         return unless mevent.pos >= @start_pos and mevent.pos <= @stop_pos
         @events.trigger(mevent)
      end
   end
end

module ICurses
   class IWindow
      alias :height :maxy
      alias :width  :maxx
      alias :clear_line :clrtoeol

      def cursor;  UI::Point.new(y: cury, x: curx)           end
      def pos;     UI::Point.new(y: begy, x: begx)           end
      def size;    UI::Size.new(height: maxy, width: maxx)   end

      def cursor=(new)
         move(new.y, new.x)  #or warn "Could not set cursor: #{new} #{size}"
      end

      def pos=(new)
         mvwin(new.y, new.x)
      end

      def size=(new)
         resize(new.height, new.width) or fail "Could not resize: #{new}"
      end

      def with_attr(attr)
         attron(attr); yield; attroff(attr)
      end

      def getch1(timeout=-1)
         self.timeout(timeout)
         getch
      end

      def on_line(n)       move(n, curx)                        ;self;end
      def on_column(n)     move(cury, n)                        ;self;end
      def next_line;       move(cury + 1, 0)                    ;self;end
      def mv_left(n)       move(cury, curx - 1)                 ;self;end
      def line_start(l=0)  move(l, 0)                           ;self;end
      def from_left(size)  move(cury, size)                     ;self;end
      def from_right(size) move(cury, (maxx - size))            ;self;end
      def center(size)     move(cury, (maxx / 2) - (size / 2))  ;self;end

      def center_string(string)
         center(string.size)
         addstr(string)
      self end

      def insert_top
         move(0, 0)
         insertln
      self end

      def append_bottom
         move(0, 0)
         deleteln
         move(maxy - 1, 0)
      self end
   end

   class IMouseEvent
      def pos
         UI::Point.new(x: x, y: y)
      end

      def to_fake
         IMouseEvent.new(self)
      end

      def to_s
         name = ICurses.constants.
            select { |c| c =~ /^BUTTON_/ }.
            select { |c| ICurses.const_get(c) & @bstate > 0 }[0]
         name ||= @button
         "[(IMouseEvent) button=#{name}, x=#{x}, y=#{y}, z=#{z}]"
      end
   end
end

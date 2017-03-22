require 'curses'
require 'readline'
require 'io/console'

require_relative 'ui/colors'
require_relative 'events'

module UI
   CONDITION_SIGNALS = ConditionSignals.new

   class WidgetSizeError < Exception; end

   class Canvas
      extend Curses

      def self.size
         UI::Size.new(height: Curses.lines, width: Curses.cols)
      end

      def self.cursor
         UI::Point.new(y: Curses.cury, x: Curses.curx)
      end

      def self.pos
         UI::Point.new
      end

      def self.start
         @@widget = nil

         %w(init_screen crmode noecho start_color use_default_colors).
            each {|_|Curses.send(_)}
         Curses.mousemask(Curses::ALL_MOUSE_EVENTS)
         Curses.stdscr.keypad(true)
         UI::Colors.start

         self.enable_resize_detection
      end

      def self.enable_resize_detection
         Signal.trap('WINCH') { @@want_resize = true }
      end

      def self.widget;      @@widget                   end
      def self.widget=(w)   @@widget = w               end
      def self.stop;        Curses.close_screen        end
      def self.visible?;    true                       end
      def self.inivsibile?; false                      end

      def self.sub(cls, **opts)
         @@widget ||= (widget = cls.new(parent: self, **opts))
         widget
      end

      def self.getch(timeout=-1)
         Curses.stdscr.timeout=(timeout)
         UI::Input::KEYMAP_WORKAROUND[Curses.stdscr.getch]
      end
      
      def self.update_screen(force_redraw=false)
         @@updating ||= Mutex.new
         @@want_resize ||= false

         if @@updating.try_lock
            begin
               if @@want_resize
                  @@want_resize = false
                  h, w = IO.console.winsize()
                  Curses.resizeterm(h, w)
                  Curses.clear
                  Curses.refresh
                  @@widget.size=(Size.new(height: h, width: w)) if @@widget
                  @@widget.display(true, true, true) if @@widget
               else
                  @@widget.display(true, force_redraw) if @@widget
               end
            rescue UI::WidgetSizeError
               Curses.clear
               Curses.addstr('terminal too small!')
            rescue
               Ektoplayer::Application.log(self, $!)
            end

            Curses.doupdate
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
         13  => Curses::KEY_ENTER,
         127 => Curses::KEY_BACKSPACE
      }
      KEYMAP_WORKAROUND.default_proc = proc { |h,k| k }
      KEYMAP_WORKAROUND.freeze

      #def self.getch(timeout=-1)
      #   KEYMAP_WORKAROUND[@@widget.getch(timeout)]
      #end

      def self.start_loop
         @@readline_obj ||= ReadlineWindow.new

         loop do
            unless @@readline_obj.active?
               Curses.curs_set(0)
               Curses.nonl

               begin
                  UI::Canvas.widget.win.keypad=(true)
                  c = KEYMAP_WORKAROUND[UI::Canvas.widget.win.getch1]

                  if c == Curses::KEY_MOUSE
                     if c = Curses.getmouse
                        UI::Canvas.widget.mouse_click(c)
                     end
                  elsif c # (not nil)
                     UI::Canvas.widget.key_press(c.is_a?(Integer) ? c : c.to_sym)
                  end
               end while !@@readline_obj.active?
            else
               Curses.curs_set(1)
               Curses.nl

               begin
                  win = UI::Canvas.widget.win
                  win.keypad=(false)
                  next unless (c = win.getch1)

                  if c == 10 or c == 4
                     @@readline_obj.feed(?\n)
                  else
                     @@readline_obj.feed(c.chr)

                     if c == 27 # pass 3-character escape sequence
                        if c = win.getch1(1)
                           @@readline_obj.feed(c.chr)
                           if c = win.getch1(1)
                              @@readline_obj.feed(c.chr)
                           end
                        end
                     end
                  end
               rescue
                  # getch() returned something weird that could not be chr()d
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
         @mutex, @cond = Mutex.new, ConditionVariable.new
         Readline.input, @readline_in_write = IO.pipe
         Readline.output = File.open(File::NULL, ?w)
         @thread = nil
      end

      def active?; @thread; end

      def readline(pos, size, prompt: '', add_hist: false, &block)
         @thread ||= Thread.new do
            begin
               window = Curses::Window.new(size.height, size.width, pos.y, pos.x)

               rlt = Thread.new { block.(Readline.readline(prompt, add_hist)) }
               Readline.set_screen_size(size.height, size.width)
               Readline.delete_text
               @readline_in_write.read_nonblock(100) rescue nil

               while rlt.alive?
                  window.erase
                  buffer = prompt + Readline.line_buffer.to_s
                  window.addstr(buffer[(buffer.size - size.width).clamp(0, buffer.size)..-1])
                  window.cursor=(Point.new(x: Readline.point + prompt.size, y: 0))
                  window.refresh
                  CONDITION_SIGNALS.wait(:readline, 0.2)
               end
            ensure
               @thread = nil
               window.clear
               UI::Canvas.update_screen(true)
            end
         end
      end

      def feed(c)
         @readline_in_write.write(c)
         CONDITION_SIGNALS.signal(:readline)
         @thread = nil if c == ?\n
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
   
   # We want to change the mouse coordinates as we pass the mouse event
   # through the widgets. The attributes of Curses::MouseEvent are
   # readonly, therefore we need to carry out our own MouseEvent class.
   class FakeMouseEvent
      attr_accessor :x, :y, :z, :bstate

      def initialize(mouse_event=nil)
         if mouse_event
            from_mouse_event!(mouse_event)
         else
            @x, @y, @z, @bstate = 0, 0, 0, Curses::BUTTON1_CLICKED
         end
      end

      def from_mouse_event!(m)
         @x, @y, @z, @bstate = m.x, m.y, m.z, m.bstate
      end

      def update!(x: nil, y: nil, z: nil, bstate: nil)
         @x, @y, @z = (x or @x), (y or @y), (z or @z)
         @bstate = (bstate or @bstate)
      end

      def pos
         Point.new(x: @x, y: @y)
      end

      def to_fake
         FakeMouseEvent.new(self)
      end

      def to_s
         name = Curses.constants.
            select { |c| c =~ /^BUTTON_/ }.
            select { |c| Curses.const_get(c) & @bstate > 0 }[0]
         name ||= @button
         "[(FakeMouseEvent) button=#{name}, x=#{x}, y=#{y}, z=#{z}]"
      end
   end

   class MouseEvents < Events
      def on(mouse_event, &block)
         return on_all(&block) if mouse_event == Curses::ALL_MOUSE_EVENTS
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

module Curses
   class Window
      alias :height :maxy
      alias :width  :maxx
      alias :clear_line :clrtoeol

      def cursor;  UI::Point.new(y: cury, x: curx)           end
      def pos;     UI::Point.new(y: begy, x: begx)           end
      def size;    UI::Size.new(height: maxy, width: maxx)   end

      def cursor=(new)
         setpos(new.y, new.x) # or fail "Could not set cursor: #{new} #{size}"
      end

      def pos=(new)
         move(new.y, new.x)
      end

      def size=(new)
         resize(new.height, new.width) or fail "Could not resize: #{new}"
      end

      def with_attr(attr)
         attron(attr); yield; attroff(attr)
      end

      def getch1(timeout=-1)
         self.timeout=(timeout)
         getch
      end

      def on_line(n)       setpos(n, curx)                        ;self;end
      def on_column(n)     setpos(cury, n)                        ;self;end
      def next_line;       setpos(cury + 1, 0)                    ;self;end
      def mv_left(n)       setpos(cury, curx - 1)                 ;self;end
      def line_start(l=0)  setpos(l, 0)                           ;self;end
      def from_left(size)  setpos(cury, size)                     ;self;end
      def from_right(size) setpos(cury, (maxx - size))            ;self;end
      def center(size)     setpos(cury, (maxx / 2) - (size / 2))  ;self;end

      def center_string(string)
         center(string.size)
         addstr(string)
      self end

      def insert_top
         setpos(0, 0)
         insertln
      self end

      def append_bottom
         setpos(0, 0)
         deleteln
         setpos(maxy - 1, 0)
      self end
   end

   class MouseEvent
      def pos
         UI::Point.new(x: x, y: y)
      end

      def to_fake
         UI::FakeMouseEvent.new(self)
      end
   end
end

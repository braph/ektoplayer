require 'thread'
require 'open3'
require 'scanf'
require 'time'

require_relative '../events'

unless system('mpg123 --version >/dev/null 2>/dev/null')
   fail LoadError, 'MpgWrapperPlayer: /bin/mpg123 not found'
end

class MpgWrapperPlayer 
   attr_reader :events, :file

   STATE_STOPPED, STATE_PAUSED, STATE_PLAYING = 0, 1, 2
   CMD_FORMAT = 'FORMAT'.freeze
   CMD_SAMPLE = 'SAMPLE'.freeze

   def initialize(audio_system)
      @audio_system = audio_system
      @events = Events.new(:play, :pause, :stop, :position_change)
      @lock = Mutex.new
      @mpg123_in, @mpg123_out, @mpg123_thread = nil, nil, nil
      @state = 0
      @file = ''

      @polling_interval = 0.9

      @seconds_played = @seconds_total = 0
      @track_completed = nil
   end

   # NOTE
   # Since ektoplazm.com switched to Cloudflare (using HTTP/2.0) mpg123
   # cannot handle those streams anymore. This may change in future versions
   # of mpg123.
   def can_http?; false; end

   def play(file=nil)
      start_mpg123_thread
      @track_completed = :track_completed
      @file = file if file
      write("L #{@file}")
      Thread.new { sleep 3; write(CMD_FORMAT) }
   end

   def pause;  write(?P) if @state == STATE_PLAYING end
   def toggle; write(?P)                            end

   def stop
      stop_polling_thread
      @track_completed = nil
      @seconds_played = @seconds_total = 0
      @events.trigger(:position_change)
      @events.trigger(:stop)
      write(?Q) if @state != STATE_STOPPED
   end

   def paused?;  @state == STATE_PAUSED  end
   def stopped?; @state == STATE_STOPPED end
   def playing?; @state == STATE_PLAYING end

   def status
      return :playing if playing?
      return :paused  if paused?
      return :stopped if stopped?
   end

   def position; @seconds_played  end
   def length;   @seconds_total   end

   def position_percent
      @seconds_played.to_f / length rescue 0.0
   end

   def seek(seconds)        write("J  #{seconds}s") end
   def rewind(seconds = 2)  write("J -#{seconds}s") end
   def forward(seconds = 2) write("J +#{seconds}s") end
   alias :backward :rewind

   private def write(string)
      @lock.synchronize { @mpg123_in.write(string + ?\n) }
   rescue
      nil
   end

   def use_polling(interval)
      @polling_interval = interval
      start_polling_thread
   end

   private def start_polling_thread
      write('SILENCE')
      @polling_thread ||= Thread.new do
         loop do
            sleep @polling_interval
            write(CMD_SAMPLE)
         end
      end
   end

   private def stop_polling_thread
      @polling_thread.kill if @polling_thread
      @polling_thread = nil
   end

   define_method '@FORMAT' do |line|
      @sample_rate, channels = line.scanf('%d %d')
   end

   define_method '@SAMPLE' do |line|
      @sample_rate ||= 44100
      samples_played, samples_total = line.scanf('%f %f')
      @seconds_played = samples_played / @sample_rate rescue 0.0
      @seconds_total = samples_total / @sample_rate rescue 0.0
      @events.trigger(:position_change)
   end

   define_method '@F' do |line|
      _, _, @seconds_played, seconds_remaining = line.scanf('%d %d %f %f')
      @seconds_total = @seconds_played + seconds_remaining
      @events.trigger(:position_change)
   end

   define_method '@P' do |line|
      if (@state = line.to_i) == STATE_STOPPED
         @events.trigger(:stop, @track_completed)
      elsif @state == STATE_PAUSED
         @events.trigger(:pause)
      elsif @state == STATE_PLAYING
         @events.trigger(:play)
      end
   end

   private def start_mpg123_thread
      @lock.synchronize do
         unless @mpg123_thread
            Thread.new do
               begin
                  @mpg123_in, @mpg123_out, mpg123_err, @mpg123_thread =
                     Open3.popen3('mpg123', '-o', @audio_system, '--fuzzy', '-R')

                  while (line = @mpg123_out.readline)
                     cmd, line = line.split(' ', 2)
                     send(cmd, line) rescue nil
                  end
               rescue
                  Ektoplayer::Application.log(self, $!)
               ensure
                  begin msg = mpg123_err.read
                  rescue
                     msg = ''
                  end

                  Ektoplayer::Application.log(self, 'player closed:', msg)
                  @mpg123_thread.kill if @mpg123_thread
                  (@mpg123_in.close rescue nil)  if @mpg123_in
                  (@mpg123_out.close rescue nil) if @mpg123_out
                  @mpg123_thread = nil
                  stop_polling_thread
               end
            end

            sleep 0.1 while not @mpg123_thread
         end
      end

      start_polling_thread if @polling_interval > 0
   end
end

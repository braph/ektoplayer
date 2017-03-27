require 'thread'
require 'open3'
require 'scanf'

require_relative '../events'

fail LoadError, 'MpgWrapperPlayer: mpg123 not found' unless system('which mpg123 >/dev/null')

class MpgWrapperPlayer 
   attr_reader :events, :file

   STATE_STOPPED, STATE_PAUSED, STATE_PLAYING = 0, 1, 2

   def initialize
      @events = Events.new(:play, :pause, :stop, :position_change)
      @lock = Mutex.new
      @mpg123_in, @mpg123_out, @mpg123_thread = nil, nil, nil
      @state = 0
      @file = ''

      @polling_interval = 1

      @frames_played = @frames_remaining =
         @seconds_played = @seconds_remaining = 0
   end

   def play(file=nil)
      start_mpg123_thread
      @file = file if file
      write("L #{@file}")
   end

   def pause;  write(?P) if @state == STATE_PLAYING end
   def stop;   write(?S) if @state != STATE_STOPPED end
   def toggle; write(?P)                            end

   def level;    30                      end
   def paused?;  @state == STATE_PAUSED  end
   def stopped?; @state == STATE_STOPPED end
   def playing?; @state == STATE_PLAYING end

   def status
      return :playing if playing?
      return :paused  if paused?
      return :stopped if stopped?
   end

   def position; @seconds_played                      end
   def length;   @seconds_played + @seconds_remaining end
   def position_percent; Float(@seconds_played) / length end

   def seek(seconds)        write("J #{seconds}s")  end
   def rewind(seconds = 2)  write("J -#{seconds}s") end
   def forward(seconds = 2) write("J +#{seconds}s")  end
   alias :backward :rewind

   private def write(string)
      @lock.synchronize do
         @mpg123_in.write(string + ?\n)
      end
   rescue
      Ektoplayer::Application.log(self, $!)
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
            write('FORMAT')
            write('SAMPLE')
         end
      end
   end

   private def start_mpg123_thread
      @lock.synchronize do
         unless @mpg123_thread
            Thread.new do
               begin
                  @mpg123_in, @mpg123_out, _, @mpg123_thread =
                     Open3.popen3('mpg123', '-o', 'jack,pulse,alsa,oss', '--fuzzy', '-R')

                  while (line = @mpg123_out.readline)
                     if line.start_with?('@FORMAT')
                        @sample_rate, channels = line.scanf('@FORMAT %d %d')
                     elsif line[1] == ?F 
                        @frames_played, @frames_remaining,
                           @seconds_played, @seconds_remaining =
                           line.scanf('@F %d %d %f %f')
                        @events.trigger(:position_change)
                     elsif line.start_with?('@SAMPLE')
                        @sample_rate ||= 44100
                        @samples_played, samples_total = 
                           line.scanf('@SAMPLE %d %d')
                        @seconds_played = @samples_played / @sample_rate rescue 0
                        seconds_total = samples_total / @sample_rate rescue 0
                        @seconds_remaining = seconds_total - @seconds_played
                        @events.trigger(:position_change)
                     elsif line[1] == ?P
                        if (@state = line[3].to_i) == STATE_STOPPED
                           if @frames_remaining < 3
                              @events.trigger(:stop, :track_completed)
                           else
                              @events.trigger(:stop)
                           end
                        elsif @state == STATE_PAUSED
                           @events.trigger(:pause)
                        elsif @state == STATE_PLAYING
                           @events.trigger(:play)
                        end
                     end
                  end
               rescue
                  Ektoplayer::Application.log(self, $!)
               ensure
                  # shouldn't reach here
                  Ektoplayer::Application.log(self, 'player closed')
                  @mpg123_thread.kill
                  @mpg123_thread = nil
                  @mpg123_in.close
                  @mpg123_out.close
               end
            end

            sleep 0.1 while not @mpg123_thread
         end
      end

      start_polling_thread if @polling_interval > 0
   end
end

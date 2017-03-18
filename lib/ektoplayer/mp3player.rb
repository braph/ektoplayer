require 'thread'
require 'mpg123'
require 'portaudio'

require_relative 'events'

class Mpg123
   alias :samples_per_frame :spf
   alias :time_per_frame :tpf

   def samples_to_frames(samples)
      samples / samples_per_frame
   end

   def seconds_to_frames(seconds)
      seconds / time_per_frame
   end

   def seconds_to_samples(seconds)
      seconds_to_frames(seconds) * samples_per_frame
   end

   def samples_to_seconds(samples)
      samples_to_frames(samples) * time_per_frame
   end

   def length_in_seconds
      samples_to_frames(length) * time_per_frame
   end

   def tell_in_seconds
      samples_to_frames(tell) * time_per_frame
   end

   def seek_in_seconds(seconds)
      samples = seconds_to_samples(seconds)
      seek(samples) if (0..length).include?(samples)
   end
end

class Mp3Player
   attr_reader :events

   def initialize(buffer_size = 2**12)
      @events = Events.new(:play, :pause, :stop, :position_change)
      @portaudio = Portaudio.new(buffer_size)
      @lock = Mutex.new
   end

   def play(song=nil)
      @lock.synchronize do
         @mp3 = Mpg123.new(song) if song
         return unless @mp3

         @portaudio.start if @portaudio.stopped?
         @portaudio_thr ||= Thread.new do
            begin
               while @mp3
                  status = @portaudio.write_from_mpg(@mp3)
                  @events.trigger(:position_change)
                  break if status == :done or status == :need_more
                  @portaudio.wait
               end
            rescue => e
               Application.log(self.class, e)
            ensure
               @portaudio_thr = nil
               if status == :done or status == :need_more
                  @events.trigger(:stop, :track_completed)
               elsif stopped?
                  @events.trigger(:stop)
               elsif paused?
                  @events.trigger(:pause)
               end
            end
         end

         @events.trigger(:position_change)
         @events.trigger(:play)
      end
   end

   def pause
      @lock.synchronize do
         @portaudio_thr.kill rescue nil
         @events.trigger(:position_change)
         @events.trigger(:pause)
      end
   end

   def stop
      @lock.synchronize do
         @portaudio_thr.kill rescue nil
         (@mp3.seek(0) rescue nil) if @mp3
         @events.trigger(:position_change)
         @events.trigger(:stop)
      end
   end

   def file;     @mp3.file if @mp3         end
   def level;    @portaudio.rms            end
   def toggle;   playing? ? pause : play   end
   def playing?; @portaudio_thr            end
   
   def paused?
      not @portaudio_thr and (@mp3 and @mp3.tell.to_i != 0)
   end

   def stopped?
      not @portaudio_thr and (!@mp3 or @mp3.tell_in_seconds.to_i == 0)
   end

   def status
      return :playing if playing?
      return :paused  if paused?
      return :stopped if stopped?
   end

   # Returns current song position in seconds
   def position
      @mp3 ? @mp3.tell_in_seconds : 0
   end

   # Returns current song position as percentual value to song length
   def position_percent
      @mp3 ? (Float(@mp3.tell) / @mp3.length) : 0
   end

   # Returns current song length in seconds
   def length
      @mp3 ? @mp3.length_in_seconds : 0
   end

   # Seeks the current song to position in seconds
   def seek(seconds)
      return unless @mp3
      @lock.synchronize do
         @mp3.seek_in_seconds(seconds) rescue nil
         events.trigger(:position_change, position)
      end
   end

   def rewind(seconds = 2)
      seek(position - seconds)
   end
   alias :backward :rewind

   def forward(seconds = 2)
      seek(position + seconds)
   end
end

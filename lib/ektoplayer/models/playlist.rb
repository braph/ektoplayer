require 'set'

require_relative 'model'

module Ektoplayer
   module Models
      class Playlist < Model
         REPEAT_MODES = Set.new([:none, :playlist, :track]).freeze

         attr_reader :current_playing, :repeat

         def initialize(list: [])
            super()
            @events.register(:current_changed, :changed)
            @playlist = list
            @current_playing = nil
            @repeat = :none
         end

         include Enumerable
         def each(&block) @playlist.each(&block)   end
         def [](*args)    @playlist[*args]         end
         def empty?;      @playlist.empty?         end
         def size;        @playlist.size           end

         def current_playing=(new)
            new = new.clamp(0, @playlist.size - 1) if new

            if @current_playing != new
               @current_playing = new
               events.trigger(:current_changed)
            end
         end

         def get_next_pos
            if @current_playing
               if @repeat == :track
                  return @current_playing
               elsif @current_playing + 1 >= @playlist.size
                  return 0 if @repeat == :playlist
               else
                  return @current_playing + 1
               end
            end
         end

         def repeat=(new)
            raise ArgumentError unless REPEAT_MODES.include? new
            if @repeat != new
               @repeat = new
               events.trigger(:repeat_changed)
            end
         end

         def add(*tracks)
            @playlist.concat(tracks)
            events.trigger(:changed, added: tracks)
         end

         def clear
            @playlist.clear
            events.trigger(:changed)
         end

         def delete(index)
            @playlist.delete_at(index) rescue return
            events.trigger(:changed, deleted: index)
         end
      end
   end
end

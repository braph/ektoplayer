# Event class
class Events
   # Create a new events object
   def initialize(*known_events)
      @on_all = []

      if known_events.empty?
         @map = {}
         auto_create
      else
         @map = known_events.map { |e| [e, []] }.to_h
         no_auto_create
      end
   end

   # Disables auto creation of non existent events
   def no_auto_create 
      @map.default_proc = proc { |h,k| fail KeyError, "Unknown event: #{k}" }
      self
   end

   # Enables auto creation of non existent events
   def auto_create
      @map.default_proc = proc { |h,k| h[k] = [] }
      self
   end

   # Registers a new event
   def register(*events)
      events.each { |event| @map[event] = [] }
   end
   alias :reg :register
   
   # Register hook for event
   def on(event, &block)
      fail ArgumentError unless block
      @map[event] << block
   end

   def on_multi(*events, &block)
      events.each { |event| on(event, &block) }
   end

   # Forward all events to +block(event, *args)+
   def on_all(&block)
      fail ArgumentError unless block
      @on_all << block
   end

   # Trigger event
   def trigger(event, *args)
      @on_all.each { |callback| callback.(event, *args) }

      if @map.key?(event)
         @map[event].each { |callback| callback.call(*args) }
      end
   end
end

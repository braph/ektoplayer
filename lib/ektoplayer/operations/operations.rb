module Ektoplayer
   module Operations
      # Operations
      # Since every operation is implemented excactly once
      # we don't use an Event object.
      #
      # Since doing a "class.send()" is faster than "hash[command].call()"
      # we implement the operations using an object instead of a hash.
      #
      class Operations
         # Register a new command
         def register(name, &block)
            self.define_singleton_method(name, &block)
         end
         alias :reg :register

         # Helper for registering multiple commands
         def with_register(prefix='', &block)
            reg_func = proc { |name, &blk| register("#{prefix}#{name}", &blk) }
            block.(reg_func) if block
            reg_func 
         end
      end
   end
end


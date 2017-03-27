unless Array.respond_to? :sum
   class Array
      def sum 
         reduce(:+)
      end
   end
end

unless Integer.respond_to? :clamp
   class Integer
      def clamp(min, max)
         if self < min
            min
         elsif self > max
            max
         else
            self
         end
      end
   end
end

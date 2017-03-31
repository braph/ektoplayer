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
         return min if self < min
         return max if self > max
         self
      end
   end
end

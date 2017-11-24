unless Array.public_method_defined? :sum
   class Array
      def sum 
         reduce(:+)
      end
   end
end

unless Integer.public_method_defined? :clamp
   class Integer
      def clamp(min, max)
         return min if self < min
         return max if self > max
         self
      end
   end
end

unless Integer.public_method_defined? :negative?
   class Integer
      def negative?
         return (self < 0)
      end
   end
end

unless Array.public_method_defined? :sum
   class Array
      def sum
         result = 0
         self.each { |i| result += 1 }
         result
      end
   end
end

unless Integer.public_method_defined? :clamp
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

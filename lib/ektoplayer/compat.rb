unless Array.public_method_defined? :sum
   def Array.sum
      result = 0
      self.each { |i| result += 1 }
      result
   end
end

unless Integer.public_method_defined? :clamp
   def Integer.clamp(min, max)
      if self < min
         min
      elsif self > max
         max
      else
         self
      end
   end
end

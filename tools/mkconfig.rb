#!/bin/ruby

require_relative '../lib/ektoplayer/config'
require_relative '../lib/ektoplayer/theme'
require_relative '../lib/ektoplayer/bindings'

$out = File.open('/tmp/ektoplayer.rc', ?w)

def escape(str)
   if !str.index(?') and !str.index(?\\)
      return str unless str.index(' ')
      return ?'+str+?'
   end
      
   return ?" + str.gsub(/\\/, "\\\\").gsub(/"/, "\\\"") + ?"
end

module Ektoplayer
   class Config
      def register(key, description, default, method=nil)
         default = default.to_s.dup
         default.sub!(Dir.home, ?~)
         $out.puts description.squeeze(' ').gsub(/^\s*/, '# ')
         $out.puts "set #{key} #{escape default}\n\n"
      end
      alias :reg :register
   end

   Config.new
   b = Bindings.new
   t = Theme.new

   $out.puts "\n### Bindings ###\n\n"
   $out.puts "unbind_all\n\n"
   b.bindings.each do |widget, commands|
      $out.puts "\n### #{widget}\n"

      commands.each do |name, keys|
         next if keys.empty?

         #puts b.commands[name.to_sym].gsub(/^\s*/, '# ')

         keys.map { |k| b.keyname(k) }.
            sort.each_with_index do |key,i|
            $out.puts "bind #{widget} #{key} #{name}"
         end
      end
   end

   $out.puts "\n### Theme ###\n\n"
   t.theme.each do |theme, definitions|
      cmd_name = { 0 => 'color_mono', 8 => 'color', 256 => 'color_256' }[theme]

      definitions.each do |name, definition|
         $out.puts "#{cmd_name} #{name} ".ljust(30) + definition.join(' ').gsub('-1', 'none')
      end

      $out.puts
   end
end

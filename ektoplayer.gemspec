$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'ektoplayer'
  s.version       = '0.1.11'
  s.authors       = ['Benjamin Abendroth']
  s.email         = 'braph93@gmx.de'
  s.homepage      = 'http://github.com/braph/ektoplayer'
  s.summary       = 'play or download music from ektoplazm.com'
  s.description   = 'Ektoplayer is a commandline client for http://ektoplazm.com, a website providing free electronic music such as techno, goa and psy-trance'
  s.license       = 'GPL-3.0'

  s.bindir        = 'bin'
  s.files         = Dir.glob('lib/**/*rb')
  s.executables   = ['ektoplayer']
  s.require_paths = ['lib']

  s.add_dependency 'sqlite3', '~> 1.3'
  s.add_dependency 'nokogiri', '~> 1.7'
  #s.add_dependency 'curses', '~> 1.0'

  s.requirements << 'For playback: /bin/mpg123 or the "audite-lib" RubyGem'
  s.requirements << 'For archive extracting: /bin/unzip, /bin/7z or "rubyzip" RubyGem'
  s.requirements << 'One of the following curses-gems: ffi-ncurses, curses'

  s.extra_rdoc_files = ['README.md']
end

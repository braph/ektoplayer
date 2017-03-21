%w( ../ui/widgets/container playinginfo progressbar
volumemeter splash playlist browser info help tabbar ).
   each {|_|require_relative(_)}

module Ektoplayer
   module Views
      class MainWindow < UI::VerticalContainer
         attr_reader :progressbar, :volumemeter, :playinginfo, :tabbar
         attr_reader :windows, :splash, :playlist, :browser, :info, :help

         def initialize(**opts)
            super(**opts)

            @playinginfo  = sub(PlayingInfo, size: @size.update(height: 2))
            @progressbar  = sub(ProgressBar, size: @size.update(height: 1))
            @volumemeter  = sub(VolumeMeter, size: @size.update(height: 1))
            @tabbar       = sub(TabBar,      size: @size.update(height: 1))
            @windows      = sub(UI::SwitchContainer, size: @size.calc(height: -4))
            @help         = @windows.sub(Help, visible: false)
            @info         = @windows.sub(Info, visible: false)
            @splash       = @windows.sub(Splash, visible: false)
            @browser      = @windows.sub(Browser, visible: false)
            @playlist     = @windows.sub(Playlist, visible: false)

            Config[:'tabs.widgets'].each do |widget|
               @windows.add(send(widget))
               @tabbar.add(widget)
            end

            Config[:'main.widgets'].each { |w| add(send(w)) }

            self.selected=(@windows)
            @windows.selected=(@splash)
         end

         def layout
            height = @size.height

            @playinginfo.size=(@size.update(height: 2))
            @volumemeter.size=(@size.update(height: 1))
            @progressbar.size=(@size.update(height: 1))
            @tabbar.size=(@size.update(height: 1))

            height -= 2 if @playinginfo.visible?
            height -= 1 if @volumemeter.visible?
            height -= 1 if @progressbar.visible?
            height -= 1 if @tabbar.visible?

            @windows.size=(@size.update(height: height))

            super
         end
      end
   end
end

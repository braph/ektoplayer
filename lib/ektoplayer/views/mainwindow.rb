%w( ../ui/widgets/tabbedcontainer playinginfo progressbar
volumemeter splash playlist browser info help ).
   each {|_|require_relative(_)}

module Ektoplayer
   module Views
      class MainWindow < UI::VerticalContainer
         attr_reader :progressbar, :volumemeter, :playinginfo
         attr_reader :tabs, :splash, :playlist, :browser, :info, :help

         def initialize(**opts)
            super(**opts)

            s1 = UI::Size.new(height: 1, width: 1) # TODO.....!!

            @playinginfo  = sub(PlayingInfo)
            @progressbar  = sub(ProgressBar)
            @volumemeter  = sub(VolumeMeter)
            @tabs         = sub(UI::TabbedContainer)
            @help         = @tabs.sub(Help, size: s1, visible: false)
            @info         = @tabs.sub(Info, size: s1, visible: false)
            @splash       = @tabs.sub(Splash, size: s1, visible: false)
            @browser      = @tabs.sub(Browser, size: s1, visible: false)
            @playlist     = @tabs.sub(Playlist, size: s1, visible: false)

            @tabs.attributes=(
               %w(tab_selected tabs).map do |attr|
                  [attr.to_sym, Theme[attr.to_sym]]
               end.to_h
            )

            Config[:'tabs.widgets'].each do |widget|
               @tabs.add(send(widget), widget)
            end

            Config[:'main.widgets'].each { |w| add(send(w)) }
            self.selected=(@tabs)
         end

         def layout
            height = @size.height

            if @playinginfo.visible?
               @playinginfo.size=(@size.update(height: 2))
               height -= 2
            end

            if @volumemeter.visible?
               @volumemeter.size=(@size.update(height: 1))
               height -= 1
            end

            if @progressbar.visible?
               @progressbar.size=(@size.update(height: 1))
               height -= 1
            end

            @tabs.size=(@size.update(height: height))

            super
         end
      end
   end
end

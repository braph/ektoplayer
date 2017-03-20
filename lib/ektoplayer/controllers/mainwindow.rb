require_relative 'controller'

module Ektoplayer
   module Controllers
      class MainWindow < Controller
         def initialize(view, view_operations)
            super(view)
            ops = view_operations
            ops.reg('splash.show')   { view.windows.selected=(view.splash)   }
            ops.reg('playlist.show') { view.windows.selected=(view.playlist) }
            ops.reg('browser.show')  { view.windows.selected=(view.browser)  }
            ops.reg('info.show')     { view.windows.selected=(view.info)     }
            ops.reg('help.show')     { view.windows.selected=(view.help)     }
            ops.reg('tabs.next')     { view.windows.select_next              }
            ops.reg('tabs.prev')     { view.windows.select_prev              }

            ops.reg('tabbar.toggle') do
               view.with_lock do
                  view.tabbar.visible=(!view.tabbar.visible?)
                  view.want_layout
               end
            end

            ops.reg('playinginfo.toggle') do
               view.with_lock do
                  view.playinginfo.visible=(!view.playinginfo.visible?)
                  view.want_layout
               end
            end

            ops.reg('progressbar.toggle') do
               view.with_lock do
                  view.progressbar.visible=(!view.progressbar.visible?)
                  view.want_layout
               end
            end

            ops.reg('volumemeter.toggle') do
               view.with_lock do
                  view.volumemeter.visible=(!view.volumemeter.visible?)
                  view.want_layout
               end
            end

            view.tabbar.events.on(:tab_clicked) do |index|
               view.windows.selected_index=(index)
            end

            view.windows.events.on(:changed) do |index|
               view.tabbar.selected=(index)
            end
         end
      end
   end
end

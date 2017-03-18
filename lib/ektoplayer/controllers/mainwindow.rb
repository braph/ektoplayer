require_relative 'controller'

module Ektoplayer
   module Controllers
      class MainWindow < Controller
         def initialize(view, view_operations)
            super(view)
            ops = view_operations
            ops.reg('splash.show')   { view.tabs.selected=(view.splash)   }
            ops.reg('playlist.show') { view.tabs.selected=(view.playlist) }
            ops.reg('browser.show')  { view.tabs.selected=(view.browser)  }
            ops.reg('info.show')     { view.tabs.selected=(view.info)     }
            ops.reg('help.show')     { view.tabs.selected=(view.help)     }
            ops.reg('tabs.next')     { view.tabs.next                     }
            ops.reg('tabs.prev')     { view.tabs.prev                     }

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
         end
      end
   end
end

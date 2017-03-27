require_relative 'model'

module Ektoplayer
   module Models
      class Browser < Model
         PARENT_DIRECTORY = '..'.freeze

         PATHS = {
            artist:  [:artist].freeze,
            album:   [:album ].freeze,
            style:   [:style ].freeze,
            year:    [:year  ].freeze,
            title:   [].freeze
         }.freeze

         def initialize(client)
            super()
            @events.register(:changed)
            @stack = []
            @stack << BrowserRoot.new(client.database)
         end

         def current
            @stack[-1]
         end

         def tracks(index)
            current.tracks(index)
         end

         def reload
            current.reload
            @events.trigger(:changed)
         end

         def enter(index)
            return false unless (sub = current.enter(index))
            return back() if sub == :parent
            @stack.push(sub)
            @events.trigger(:changed)
            true
         end

         def back
            return false unless @stack.size > 1
            @stack.pop
            @events.trigger(:changed)
            true
         end

         class BrowsableCollection
            include Enumerable
            def each(&block)  @contents.each(&block)  end
            def [](*args)     @contents[*args]        end
            def empty?;       @contents.empty?        end

            def initialize(database, filters, tag_hierarchy)
               @database, @tag_hierarchy = database, tag_hierarchy
               @filters = filters
               @tag = @tag_hierarchy.shift(1)[0]
               reload
            end

            def reload
               @contents = [PARENT_DIRECTORY]

               if @tag
                  @contents.concat(
                     @database.select(
                        columns: @tag,
                        filters: @filters, 
                        group_by: @tag,
                        order_by: [@tag] + @filters.map { |f| f[:tag] }
                     ).map { |r| r[0] }
                  )
               else
                  @contents.concat(
                     @database.select(filters: @filters)
                  )
               end
            end

            def enter(index)
               return :parent if index == 0
               return unless @tag
               BrowsableCollection.new(@database, new_filters(index), @tag_hierarchy)
            end

            def tracks(index)
               if not @tag
                  return [] if index == 0
                  return [ @contents[index] ]
               else
                  @database.select(filters: new_filters(index))
               end
            end

            private def new_filters(index)
               @filters.dup << { tag: @tag, operator: :==, value: @contents[index] }
            end
         end
 
         class BrowserRoot
            CONTENTS = PATHS.keys.freeze

            include Enumerable
            def each(&block)  CONTENTS.each(&block)  end
            def [](*args)     CONTENTS[*args]        end
            def empty?;       CONTENTS.empty?        end

            def initialize(database)
               @database = database
            end

            def reload; end

            def enter(index)
               fail unless path = PATHS[CONTENTS[index]]
               BrowsableCollection.new(@database, [], path.dup)
            end

            def tracks(index)
               @database.select(
                  order_by: CONTENTS[index].to_s + ",album,year,number".sub(",#{CONTENTS[index]}", '')
               )
            end
         end
      end
   end
end

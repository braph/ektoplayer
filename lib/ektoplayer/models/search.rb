require_relative 'model'

module Ektoplayer
   module Models
      class Search < Model
         include Enumerable
         def each(&block)  @contents.each(&block)  end
         def [](*args)     @contents[*args]        end

         def initialize(client, sort: 'date')
            super()
            @params = { sort: 'date' }
            @db = client.database
            @events.register(:changed)
            #reload { sort: 'date' }.update(params)
         end

         def reload(new_params)
            return if new_params == @params
            @params = new_params

            @contents = @db.select(
               order_by:  "#{@params[:sort]}, album, number",
               filters: todo #TODO
            )
            @events.trigger(:changed)
         end

         def completion_for(tag)
            @db.select(columns: tag, group_by: tag, order_by: tag)
         end

         def sort(new)
            reload @param.dup.update(sort: new)
         end

         def by_tag(tag, operator, value)
            reload @param.dup.update()
         end
      end
   end
end

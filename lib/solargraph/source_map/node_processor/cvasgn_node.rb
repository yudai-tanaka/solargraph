module Solargraph
  class SourceMap
    module NodeProcessor
      class CvasgnNode < Base
        def process
          loc = get_node_location(node)
          pins.push Solargraph::Pin::ClassVariable.new(
            location: loc,
            closure: closure_pin(loc.range.start),
            name: node.children[0].to_s,
            comments: comments_for(node),
            assignment: node.children[1]
          )
          process_children
        end
      end
    end
  end
end

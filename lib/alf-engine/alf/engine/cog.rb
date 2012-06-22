module Alf
  module Engine
    class Cog
      include Enumerable

      # Execution context
      attr_reader :context

      def initialize(context)
        @context = context
      end

    private

      def tuple_scope(tuple = nil)
        Tools::TupleScope.new tuple, [], context && context.scope
      end

    end # module Cog
  end # module Engine
end # module Alf

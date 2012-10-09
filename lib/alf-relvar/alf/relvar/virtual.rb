module Alf
  module Relvar
    class Virtual
      include Relvar

      def initialize(expr, connection = nil)
        @expr = expr
        @connection = connection
      end
      attr_reader :expr

      ### Static analysis & inference

      def heading
        expr.heading
      end

      def keys
        expr.keys
      end

      ### Update

      # Inserts some tuples inside this relation variable.
      def insert(tuples)
        tuples = [ tuples ] if TupleLike===tuples
        Update::Inserter.new.call(expr, tuples)
      end

      # Updates all tuples of this relation variable.
      def update(computation, predicate = Predicate.tautology)
        Update::Updater.new.call(expr, computation, predicate)
      end

      # Delete all tuples of this relation variable.
      def delete(predicate = Predicate.tautology)
        Update::Deleter.new.call(expr, predicate)
      end

      ### to_xxx

      def to_cog
        connection!.compile(expr)
      end

      def to_lispy
        expr.to_lispy
      end

      def to_s
        "Relvar::Virtual(#{expr})"
      end

    private

      def _self_operand
        expr
      end

    end # class Base
  end # module Relvar
end # module Alf

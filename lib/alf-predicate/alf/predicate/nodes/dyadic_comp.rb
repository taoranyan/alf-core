module Alf
  class Predicate
    module DyadicComp
      include Expr

      def priority
        50
      end

      def !
        Factory.send(OP_NEGATIONS[first], last)
      end

      def left
        self[1]
      end

      def right
        self[2]
      end

      def free_variables
        @free_variables ||= left.free_variables | right.free_variables
      end

      def and_split(attr_list)
        (free_variables & attr_list).empty? ? [ tautology, self ] : [ self, tautology ]
      end

    end
  end
end

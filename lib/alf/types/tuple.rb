module Alf
  module Types
    module Tuple

      def project(attr_list)
        Tuple Hash[attr_list.to_a.map{|k| [k, self[k]] }]
      end

      def allbut(attr_list)
        project(AttrList.new(keys) - attr_list)
      end

      def only(renaming)
        renaming = Renaming.coerce(renaming)
        Tuple Hash[renaming.to_hash.each_pair.map{|o,n| [n, self[o]] }]
      end

      def extend(computation)
        computation = TupleComputation.coerce(computation)
        scope       = TupleScope.new(self)
        computed    = computation.evaluate(scope)
        Tuple self.merge(computed)
      end

    end # module Tuple
  end # module Types
end # module Alf
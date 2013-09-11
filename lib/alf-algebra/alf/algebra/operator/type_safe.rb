module Alf
  module Algebra
    class TypeSafe
      include Operator
      include NonRelational
      include Unary

      signature do |s|
        s.argument :type_safe_heading, Heading, nil
        s.option   :strict, Boolean,  false, 'Be strict, not allowing tuple projections?'
      end

      def heading
        type_safe_heading
      end

      def keys
        operand.keys
      end

    end # class TypeSafe
  end # module Algebra
end # module Alf

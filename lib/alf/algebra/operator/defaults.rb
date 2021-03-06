module Alf
  module Algebra
    class Defaults
      include Operator
      include NonRelational
      include Unary

      signature do |s|
        s.argument :defaults, TupleComputation, {}
        s.option   :strict,   Boolean, false, "Restrict to default attributes only?"
      end

      def heading
        @heading ||= begin
          defh = defaults.to_heading
          strict ? defh : operand.heading.merge(defh)
        end
      end

      def keys
        @keys ||= operand.keys
      end

    private

      def _type_check(options)
      end

    end # class Defaults
  end # module Algebra
end # module Alf

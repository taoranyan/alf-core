module Alf
  module Algebra
    class Wrap
      include Operator
      include Relational
      include Unary

      signature do |s|
        s.argument :attributes, AttrList, []
        s.argument :as, AttrName, :wrapped
        s.option   :allbut, Boolean,  false, 'Wrap all but specified attributes?'
      end

      def heading
        @heading ||= stay_heading.merge(as => Tuple[wrapped_heading])
      end

      def keys
        @keys ||= operand.keys.map{|k|
          rest = k.project(attributes, !allbut)
          (rest == k) ? rest : (rest | [ as ])
        }
      end

      def wrapped_heading
        @wrapped_heading ||= operand.heading.project(attributes, allbut)
      end

      def wrapped_attrs
        @wrapped_attrs ||= wrapped_heading.to_attr_list
      end

      def stay_heading
        @stay_heading ||= operand.heading.project(attributes, !allbut)
      end

      def stay_attrs
        @stay_attrs ||= wrapped_heading.to_attr_list
      end

    private

      def _type_check(options)
        no_unknown!(attributes - operand.attr_list)
        no_name_clash!(operand.attr_list - attributes, AttrList[as])
      end

    end # class Wrap
  end # module Algebra
end # module Alf

module Alf
  module Types
    #
    # A tuple expression is a Ruby expression whose evaluates in the scope of a specific
    # tuple.
    #
    # Example:
    #   expr = TupleExpression["status * 10"]
    #   expr.call(:status => 20)
    #   # => 200
    #
    class TupleExpression

      # @return [Proc] the lambda expression
      attr_reader :expr_lambda

      # @return [String] the expression source code (may be nil)
      attr_reader :source

      # @return [Class] the resulting type (Object by default)
      attr_reader :result_type

      # Creates a tuple expression from a Proc object
      #
      # @param [Proc] expr a Proc for the expression
      # @param [String] source the source code of the expression (optional)
      def initialize(expr, source = nil, result_type = Object)
        @expr_lambda = expr
        @source = source
        @result_type = result_type
      end

      class << self

        # Coerces `arg` to a tuple expression.
        #
        # Implemented coercions are:
        # - TupleExpression -> self
        # - Proc            -> TupleExpression.new(arg, nil)
        # - Symbol          -> TupleExpression.new(..., arg)
        #
        # @param [Object] arg a value to convert to a tuple expression
        # @return [TupleExpression] the expression if coercion succeeds
        # @raise [ArgumentError] if the coercion fails
        def coerce(arg)
          case arg
          when TupleExpression
            arg
          when Proc
            TupleExpression.new(arg)
          when AttrName
            TupleExpression.new(eval("->(t){ t.#{arg} }"), "t.#{arg}")
          else
            raise ArgumentError, "Invalid argument `#{arg}` for TupleExpression()"
          end
        end
        alias :[] :coerce

      end # class << self

      # Evaluates the expression in the context of a TupleScope
      #
      # @param [TupleScope] scope a tuple scope instance.
      # @return [Object] the result of evaluating the expression in the context
      #         of `scope`
      def evaluate(scope = nil)
        result = if @expr_lambda.arity == 1
          @expr_lambda.call(scope)
        else
          scope.instance_exec(&@expr_lambda)
        end
        looks_an_expression?(result) ? result.to_relation : result
      end

      # Infers the resulting type.
      #
      # @return [Class] the type inferred from expression source code
      def infer_type
        result_type || Object
      end

      # Returns a hash code.
      #
      # @return [Integer] a hash code for this expression
      def hash
        @source.nil? ? @expr_lambda.hash : @source.hash
      end

      # Checks equality with another expression
      #
      # @param [TupleExpression] another expression.
      # @return [Boolean] true if self and other are equal, false otherwise
      def ==(other)
        return false unless other.is_a?(TupleExpression)
        if source.nil? || other.source.nil?
          expr_lambda == other.expr_lambda
        else
          source == other.source
        end
      end
      alias :eql? :==

      # Returns a lispy expression.
      #
      # @return [String] a lispy expression for this tuple expression
      def to_lispy
        "->(t){ #{has_source_code!} }"
      rescue NotImplementedError => ex
        "->(t){ [code unavailable] }"
      end

      # Returns a ruby literal for this expression.
      #
      # @return [String] a literal s.t. `eval(self.to_ruby_literal) == self`
      def to_ruby_literal
        "Alf::#{Support.class_name(self.class)}[#{Support.to_ruby_literal(has_source_code!)}]"
      end

      # Asserts that this expression knows its source code or raises a
      # NotImplementedError.
      #
      # @return [String] the source code when known
      def has_source_code!
        if source.nil?
          raise NotImplementedError, "No known source code for this expression"
        else
          source
        end
      end

    private

      def looks_an_expression?(y)
        Algebra::Operand::Named === y || Algebra::Operator === y
      end

    end # class TupleExpression
  end # module Types
end # module Alf

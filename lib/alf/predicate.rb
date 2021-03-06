require_relative 'predicate/factory'
require_relative 'predicate/grammar'
require_relative 'predicate/processors'
module Alf
  class Predicate

    def initialize(sexpr)
      @sexpr = sexpr
    end
    attr_reader :sexpr
    alias :expr :sexpr

    class << self
      include Factory

      def coerce(arg)
        case arg
        when Predicate   then arg
        when TrueClass   then tautology
        when FalseClass  then contradiction
        when Symbol      then identifier(arg)
        when Proc        then native(arg)
        when Hash, Tuple then eq(arg)
        when Relation    then relation(arg)
        else
          raise ArgumentError, "Unable to coerce `#{arg}` to a predicate"
        end
      end
      alias :parse :coerce

    private

      def _factor_predicate(arg)
        Predicate.new Grammar.sexpr(arg)
      end

    end

    def native?
      Native===expr
    end

    def tautology?
      expr.tautology?
    end

    def contradiction?
      expr.contradiction?
    end

    def free_variables
      expr.free_variables
    end

    def constant_variables
      expr.constant_variables
    end

    def &(other)
      return self  if other.tautology? or other==self
      return other if tautology?
      Predicate.new(expr & other.expr)
    end

    def |(other)
      return self  if other.contradiction? or other==self
      return other if contradiction?
      Predicate.new(expr | other.expr)
    end

    def !
      Predicate.new(!expr)
    end

    def qualify(qualifier)
      Predicate.new(expr.qualify(qualifier))
    end

    def rename(renaming)
      Predicate.new(expr.rename(renaming))
    end

    def evaluate(scope)
      proc = to_proc
      if proc.arity == 1
        proc.call(scope)
      else
        scope.instance_exec(&to_proc)
      end
    end

    def and_split(attr_list)
      expr.and_split(attr_list).map{|e| Predicate.new(e)}
    end

    def ==(other)
      other.is_a?(Predicate) && (other.expr==expr)
    end
    alias :eql? :==

    def hash
      expr.hash
    end

    def to_ruby_code(scope = "t")
      expr.to_ruby_code(scope)
    end
    alias :to_s :to_ruby_code

    def to_proc
      @proc ||= expr.to_proc("t")
    end

    def to_lispy
      to_ruby_code
    end

    def to_ruby_literal
      to_lispy
    end

  end # class Predicate
end # module Alf

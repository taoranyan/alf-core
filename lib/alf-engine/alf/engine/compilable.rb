module Alf
  module Engine
    class Compilable

      def initialize(cog)
        @cog = cog
        @parser = Lang::Lispy.new
      end

      ### main

      def compile(expr)
        send(expr.class.rubycase_name, expr)
      end

      ### non relational

      def autonum(expr, traceability = expr)
        Autonum.new(@cog, expr.as, traceability)
      end

      def clip(expr, traceability = expr)
        Clip.new(@cog, expr.attributes, expr.allbut, traceability)
      end

      def coerce(expr, traceability = expr)
        Coerce.new(@cog, expr.coercions, traceability)
      end

      def compact(expr, traceability = expr)
        Compact.new(@cog, traceability)
      end

      def defaults(expr, traceability = expr)
        compiled = Defaults.new(@cog, expr.defaults, traceability)
        if expr.strict
          clipping = @parser.clip(expr, expr.defaults.to_attr_list)
          compiled = compiled.to_compilable.clip(clipping, traceability)
        end
        compiled
      end

      def generator(expr, traceability = expr)
        Generator.new(expr.as, 1, 1, expr.size, traceability)
      end

      def sort(expr, traceability = expr)
        compiled = @cog
        unless @cog.orderedby?(expr.ordering)
          compiled = Sort.new(compiled, expr.ordering, traceability)
        end
        compiled
      end

      def type_safe(expr, traceability = expr)
        checker = TypeCheck.new(expr.heading, expr.strict)
        TypeSafe.new(@cog, checker, traceability)
      end

      ### relational

      def extend(expr, traceability = expr)
        SetAttr.new(@cog, expr.ext, traceability)
      end

      def group(expr, traceability = expr)
        Group::Hash.new(@cog, expr.attributes, expr.as, expr.allbut, traceability)
      end

      def infer_heading(expr, traceability = expr)
        InferHeading.new(@cog, traceability)
      end

      def intersect(expr, traceability = expr)
        Join::Hash.new(@cog, expr.right.compile, traceability)
      end

      def join(expr, traceability = expr)
        Join::Hash.new(@cog, expr.right.compile, traceability)
      end

      def matching(expr, traceability = expr)
        Semi::Hash.new(@cog, expr.right.compile, true, traceability)
      end

      def minus(expr, traceability = expr)
        Semi::Hash.new(@cog, expr.right.compile, false, traceability)
      end

      def not_matching(expr, traceability = expr)
        Semi::Hash.new(@cog, expr.right.compile, false, traceability)
      end

      def page(expr, traceability = expr)
        index, size = expr.page_index, expr.page_size
        #
        ordering = expr.full_ordering rescue expr.ordering
        ordering = ordering.reverse if index < 0
        #
        compiled = sort(@parser.sort(expr, ordering))
        compiled = Take.new(compiled, (index.abs - 1) * size, size, traceability)
        #
        compiled
      end

      def project(expr, traceability = expr)
        preserving = expr.key_preserving? rescue false
        #
        compiled = Clip.new(@cog, expr.attributes, expr.allbut, traceability)
        compiled = Compact.new(compiled, traceability) unless preserving
        #
        compiled
      end

      def quota(expr, traceability = expr)
        compiled = sort(@parser.sort(expr, expr.by.to_ordering + expr.order))
        compiled = Quota::Cesure.new(compiled, expr.by, expr.summarization, traceability)
        #
        compiled
      end

      def rank(expr, traceability = expr)
        compiled = sort(@parser.sort(expr, expr.order))
        compiled = Rank::Cesure.new(compiled, expr.order, expr.as, traceability)
        #
        compiled
      end

      def rename(expr, traceability = expr)
        Rename.new(@cog, expr.renaming, traceability)
      end

      def restrict(expr, traceability = expr)
        Filter.new(@cog, expr.predicate, traceability)
      end

      def summarize(expr, traceability = expr)
        clazz = expr.allbut ? Summarize::Hash : Summarize::Cesure
        #
        compiled = @cog
        unless expr.allbut
          compiled = compiled.to_compilable.sort(@parser.sort(expr, expr.by.to_ordering))
        end
        compiled = clazz.new(compiled, expr.by, expr.summarization, expr.allbut, traceability)
        #
        compiled
      end

      def ungroup(expr, traceability = expr)
        Ungroup.new(@cog, expr.attribute, traceability)
      end

      def union(expr, traceability = expr)
        compiled = Concat.new([@cog, expr.right.compile], traceability)
        compiled = Compact.new(compiled, expr)
        #
        compiled
      end

      def unwrap(expr, traceability = expr)
        Unwrap.new(@cog, expr.attribute, traceability)
      end

      def wrap(expr, traceability = expr)
        Wrap.new(@cog, expr.attributes, expr.as, expr.allbut, traceability)
      end

      ### traceability

      def expr
        to_cog.expr
      end

      ### to_xxx

      def to_cog
        @cog
      end

    end # class Compilable
  end # module Engine
end # module Alf

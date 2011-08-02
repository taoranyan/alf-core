module Alf
  module Operator::Relational
    # 
    # Relational quota-queries (position, sum progression, etc.)
    #
    # SYNOPSIS
    #   #{program_name} #{command_name} [OPERAND] -- BY -- ORDER -- SUMMARIZATION
    #
    # OPTIONS
    # #{summarized_options}
    #
    # API & EXAMPLE
    #
    #   (quota :supplies, [:sid], [:qty],
    #                     :position => Aggregator.count,
    #                     :sum_qty  => Aggregator.sum(:qty))
    #
    # DESCRIPTION
    #
    # This operator computes quota values on input tuples.
    #
    #   alf quota supplies -- sid -- qty -- position count sum_qty "sum(:qty)"
    #
    class Quota < Alf::Operator(__FILE__, __LINE__)
      include Operator::Relational, Operator::Experimental,
              Operator::Shortcut, Operator::Unary
  
      signature do |s|
        s.argument :by, ProjectionKey, []
        s.argument :order, OrderingKey, []
        s.argument :summarization, Summarization, {}
      end
      
      class SortBased
        include Operator, Operator::Cesure
        
        def initialize(by, order, summarization)
          @by, @order, @summarization  = by, order, summarization
        end
        
        protected
        
        # (see Operator::Cesure#project)
        def project(tuple)
          @by.project(tuple, false)
        end
        
        # (see Operator::Cesure#start_cesure)
        def start_cesure(key, receiver)
          @aggs = @summarization.least
        end
    
        # (see Operator::Cesure#accumulate_cesure)
        def accumulate_cesure(tuple, receiver)
          @aggs = @summarization.happens(@aggs, tuple)
          receiver.call tuple.merge(@summarization.finalize(@aggs))
        end
  
      end # class SortBased
  
      protected
      
      def longexpr
        sort_key = @by.to_ordering_key + @order
        chain SortBased.new(@by, @order, @summarization),
              Operator::NonRelational::Sort.new(sort_key),
              datasets
      end 
  
    end # class Quota
  end # module Operator::Relational
end # module Alf
def alf_required(retried)
  ["enumerator", 
   "quickl"].each{|req| require req}
rescue LoadError
  raise if retried
  require "rubygems"
  alf_required(true)
end
alf_required(false)

#
# alf - A commandline tool for relational inspired data manipulation
#
# SYNOPSIS
#   #{program_name} [--version] [--help] 
#   #{program_name} help COMMAND
#   #{program_name} COMMAND [cmd opts] ARGS ...
#
# OPTIONS
# #{summarized_options}
#
# COMMANDS
# #{summarized_subcommands}
#
# See '#{program_name} help COMMAND' for more information on a specific command.
#
class Alf < Quickl::Delegator(__FILE__, __LINE__)

  # Handles Alf's version 
  module Version
    MAJOR = 1
    MINOR = 0
    TINY  = 0
    def self.to_s
      [ MAJOR, MINOR, TINY ].join('.')
    end
  end 
  VERSION = Version.to_s

  # Install options
  options do |opt|
    opt.on_tail("--help", "Show help") do
      raise Quickl::Help
    end
    opt.on_tail("--version", "Show version") do
      raise Quickl::Exit, "#{program_name} #{Alf::VERSION} (c) 2011, Bernard Lambeau"
    end
  end # Alf's options

  #
  # Converts an array of pairs to a Hash
  #
  def self.Hash(array)
    h = {}
    array.each{|pair| h[pair.first] = pair.last}
    h
  end

  #
  # Defines a basic Alf command
  #
  def self.Command(file, line)
    res = Quickl::Command(file, line)
    Quickl.command_builder{|b| yield(b)} if block_given?
    res
  end

  #
  # Defines a generic relational command
  #
  def self.BaseOperator(file, line)
    Command(file, line) do |b|
      b.instance_module Alf::BaseOperator
    end
  end

  #
  # Defines a command that simply transforms single tuples
  #
  def self.TupleTransformOperator(file, line)
    Command(file, line) do |b|
      b.instance_module Alf::TupleTransformOperator
    end
  end

  #
  # Defines a command that is a shortcut on a longer expression
  #
  def self.ShortcutOperator(file, line)
    Command(file, line) do |b|
      b.instance_module Alf::ShortcutOperator
    end
  end

  # 
  # Implements a small LISP-like DSL on top of Alf
  #
  module Lispy

    # Factors a DEFAULTS operator
    def defaults(child, defaults)
      _pipe(Defaults.new{|d| d.defaults = defaults}, child)
    end

    # Factors an EXTEND operator
    def extend(child, extensions)
      _pipe(Extend.new{|op| op.extensions = extensions}, child)
    end

    # Factors a PROJECT operator
    def project(child, *attrs)
      _pipe(Project.new{|p| p.attributes = attrs.flatten}, child)
    end

    # Factors a PROJECT-ALLBUT operator
    def allbut(child, *attrs)
      _pipe(Project.new{|p| p.attributes = attrs.flatten; p.allbut = true}, child)
    end

    # Factors a RENAME operator
    def rename(child, renaming)
      _pipe(Rename.new{|r| r.renaming = renaming}, child)
    end

    # Factors a RESTRICT operator
    def restrict(child, functor)
      _pipe(Restrict.new{|r| r.functor = Restrict.functor(functor)}, child)
    end

    # Factors a NEST operator
    def nest(child, nesting)
      _pipe(Nest.new{|r| r.attributes = nesting[nesting.keys.first]
                        r.as = nesting.keys.first}, child)
    end

    # Factors an UNNEST operator
    def unnest(child, attribute)
      _pipe(Unnest.new{|r| r.attribute = attribute}, child)
    end

    # Factors a GROUP operator
    def group(child, grouping)
      _pipe(Group.new{|r| r.attributes = grouping[grouping.keys.first]
                         r.as = grouping.keys.first}, child)
    end

    # Factors an UNGROUP operator
    def ungroup(child, attribute)
      _pipe(Ungroup.new{|r| r.attribute = attribute}, child)
    end

    # Factors an SORT operator
    def sort(child, attributes, direction = :asc)
      _pipe(Sort.new{|r| r.attributes = attributes;
                         r.direction = direction}, child)
    end

    private

    def _pipe(parent, child)
      child = case child
        when IO
          HashReader.new(child)
        when Array, Pipeable
          child
        else
          raise ArgumentError, "Unable to pipe with #{child}"
      end
      parent.pipe(child)
    end

    extend Lispy
  end # module Lispy

  #
  # Included by all elements of a tuple chain
  #
  module Pipeable

    # Input stream
    attr_reader :input

    #
    # Pipes with an input stream, typically a IO object
    #
    # This method simply sets _input_ under a variable instance of
    # same name and returns self.
    #
    def pipe(input)
      @input = input
      self
    end

    protected

    #
    # Yields the block with each input tuple.
    #
    # This method should be preferred to <code>input.each</code> when possible.
    #
    def each_input_tuple
      input.each &Proc.new
    end

  end # module Pipeable

  ##############################################################################
  #
  # PART I - Readers
  #
  # Readers are dataflow elements at the input boundary with the outside world.
  # They typically convert IO streams as Enumerable tuple streams. All readers
  # should follow the basis given by TupleReader.
  #
  
  #
  # Marker for chain elements converting input streams to enumerable 
  # of tuples.
  #
  module TupleReader
    include Pipeable, Enumerable

    #
    # Yields the block with each tuple (converted from the
    # input stream) in turn.
    #
    # Default implementation reads lines of the input stream and
    # yields the block with <code>_line2tuple(line)</code> on each
    # of them
    #
    def each
      input.each_line do |line| 
        tuple = _line2tuple(line)
        yield tuple unless tuple.nil?
      end
    end

    protected

    #
    # Converts a line previously read from the input stream
    # to a tuple.
    #
    # This method MUST be implemented by subclasses.
    #
    def _line2tuple(line)
    end
    undef_method :_line2tuple

  end # module TupleReader

  #
  # Implements the TupleReader contract for a stream where each line is 
  # a ruby hash literal, as a tuple physical representation.
  #
  class HashReader
    include TupleReader

    # @see TupleReader#_line2tuple
    def _line2tuple(line)
      begin
        h = Kernel.eval(line)
        raise "hash expected, got #{h}" unless h.is_a?(Hash)
      rescue Exception => ex
        $stderr << "Skipping #{line.strip}: #{ex.message}\n"
        nil
      else
        return h
      end
    end

  end # class HashReader

  #
  # Provides a handle to implement a (TODO) fly design pattern
  # on tuples.
  #
  class TupleHandle

    # Creates an handle instance
    def initialize
      @tuple = nil
    end

    #
    # Sets the next tuple to use.
    #
    # This method installs the handle as a side effect 
    # on first call. 
    #
    def set(tuple)
      build(tuple) if @tuple.nil?
      @tuple = tuple
      self
    end

    # 
    # Compiles a tuple expression and returns a lambda
    # instance that can be passed to evaluate later.
    # 
    def self.compile(expr)
      # TODO: refactor this to avoid relying on Kernel.eval
      Kernel.eval "lambda{ #{expr} }"
    end

    #
    # Evaluates an expression on the current tuple. Expression
    # can be a lambda or a string (immediately compiled in the
    # later case).
    # 
    def evaluate(expr)
      expr = TupleHandle.compile(expr) unless expr.is_a?(Proc)
      if RUBY_VERSION < "1.9"
        instance_eval &expr
      else
        instance_exec &expr
      end
    end

    private

    #
    # Builds this handle with a tuple.
    #
    # This method should be called only once and installs 
    # instance methods on the handle with keys of _tuple_.
    #
    def build(tuple)
      # TODO: refactor me to avoid instance_eval
      tuple.keys.each do |k|
        self.instance_eval <<-EOF
          def #{k}; @tuple[#{k.inspect}]; end
        EOF
      end
    end

  end # class TupleHandle

  #
  # Marker for all operators on relations.
  # 
  module BaseOperator
    include Pipeable
    include Enumerable

    #
    # Yields each tuple in turn 
    #
    # This method is implemented in a way that ensures that all operators are 
    # thread safe. It is not intended to be overriden, use _each instead.
    # 
    def each
      dup._prepare._each &Proc.new
    end

    # 
    # Executes this operator as a commandline
    #
    def execute(args)
      set_args(args)
      [ HashReader.new, self, HashWriter.new ].inject($stdin) do |chain,n|
        n.pipe(chain)
      end.execute($stdout)
    end

    #
    # Configures the operator from arguments taken from command line. 
    #
    # This method is intended to be overriden by subclasses and must return the 
    # operator itself.
    #
    def set_args(args)
      self
    end

    protected

    #
    # Prepares the iterator before subsequent call to _each.
    #
    # This method is intended to be overriden by suclasses to install what's 
    # need for successful iteration. The default implementation does nothing.
    # The method must return the operator itself.
    #
    def _prepare 
      self
    end

    # 
    # Internal implementation of the iterator.
    #
    # This method must be implemented by subclasses. It is safe to use instance
    # variables (typically initialized in _prepare) here.
    # 
    def _each
    end
    undef_method :_each

  end # module BaseOperator

  #
  # Specialization of BaseOperator for operators that
  # simply convert single tuples to single tuples.
  #
  module TupleTransformOperator
    include BaseOperator

    protected 

    # @see BaseOperator#_each
    def _each
      each_input_tuple do |tuple|
        yield _tuple2tuple(tuple)
      end
    end

    #
    # Transforms an input tuple to an output tuple
    #
    def _tuple2tuple(tuple)
    end
    undef_method :_tuple2tuple

  end # module TupleTransformOperator

  #
  # Specialization of BaseOperator for operators that are 
  # shortcuts on longer expressions.
  # 
  module ShortcutOperator
    include BaseOperator
    include Lispy

    protected 

    def _each
      longexpr.each &Proc.new
    end

  end # module ShortcutOperator

  # 
  # Normalize the input tuple stream by forcing default values
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} ATTR1 VAL1 ...
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This operator rewrites tuples so as to ensure that all specified 
  # attributes ATTR are defined and not nil. Missing or nil attributes
  # are replaced by the associated default value. 
  #
  class Defaults < Alf::TupleTransformOperator(__FILE__, __LINE__)

    # Hash of source -> target attribute renamings
    attr_accessor :defaults

    # Builds a Defaults operator instance
    def initialize
      @defaults = {}
      yield self if block_given?
    end

    # @see BaseOperator#set_args
    def set_args(args)
      args.each_with_index{|a,i| args[i] = a.to_sym if i % 2 == 0}
      @defaults = Hash[*args]
      self
    end

    protected 

    # @see TupleTransformOperator#_tuple2tuple
    def _tuple2tuple(tuple)
      @defaults.merge Alf::Hash(tuple.collect{|k,v| 
        [k, v.nil? ? @defaults[k] : v]
      })
    end

  end # class Defaults

  # 
  # Extend input tuples with attributes whose value is computed
  # with tuple expressions.
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} ATTR1 EXPR1 ATTR2 EXPR2...
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This command extend input tuples with new attributes names ATTR1 
  # ATTR2, and so on. Values of those attributes are the result of
  # evaluating EXPR1, EXPR2, etc on input tuples.
  #
  class Extend < Alf::TupleTransformOperator(__FILE__, __LINE__)

    # Extensions as a Hash attr => lambda{...}
    attr_accessor :extensions

    # Builds an Extend operator instance
    def initialize
      @extensions = {}
      yield self if block_given?
    end

    # @see BaseOperator#set_args
    def set_args(args)
      @extensions = Alf::Hash(args.each_slice(2).collect{|k,v|
        [k.to_sym, TupleHandle.compile(v)]
      })
      self
    end

    protected 

    # @see BaseOperator#_prepare
    def _prepare
      @handle = TupleHandle.new
      self
    end

    # @see TupleTransformOperator#_tuple2tuple
    def _tuple2tuple(tuple)
      tuple.merge Alf::Hash(@extensions.collect{|k,v|
        [k, @handle.set(tuple).evaluate(v)]
      })
    end

  end # class Extend

  # 
  # Project input tuples on some attributes only
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} ATTR1 ATTR2 ...
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This operator projects tuples on attributes whose names are specified 
  # as arguments. Note that, so far, this operator does NOT remove 
  # duplicate tuples in the result and is therefore not equivalent to a
  # true relational projection.
  #
  class Project < Alf::TupleTransformOperator(__FILE__, __LINE__)

    # Array of projection attributes
    attr_accessor :attributes

    # Is it a --allbut projection?
    attr_accessor :allbut

    # Builds a Project operator instance
    def initialize
      @attributes = []
      @allbut = false
      yield self if block_given?
    end

    # Installs the options
    options do |opt|
      opt.on('-a', '--allbut', 'Apply a ALLBUT projection') do
        @allbut = true
      end
    end

    # @see BaseOperator#set_args
    def set_args(args)
      @attributes = args.collect{|a| a.to_sym}
      self
    end

    protected 

    # @see TupleTransformOperator#_tuple2tuple
    def _tuple2tuple(tuple)
      @allbut ? 
        tuple.delete_if{|k,v|  attributes.include?(k)} :
        tuple.delete_if{|k,v| !attributes.include?(k)}
    end

  end # class Project

  # 
  # Rename some tuple attributes
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} OLD1 NEW1 ...
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This command renames OLD attributes as NEW as specified by 
  # arguments. Attributes OLD should exist in the source relation 
  # while attributes NEW should not.
  #
  # Example:
  #   {:id => 1} -> alf rename id identifier -> {:identifier => 1}
  #   {:a => 1, :b => 2} -> alf rename a A b B -> {:A => 1, :B => 2}
  #
  class Rename < Alf::TupleTransformOperator(__FILE__, __LINE__)

    # Hash of source -> target attribute renamings
    attr_accessor :renaming

    # Builds a Rename operator instance
    def initialize
      @renaming = {}
      yield self if block_given?
    end

    # @see BaseOperator#set_args
    def set_args(args)
      @renaming = Hash[*args.collect{|c| c.to_sym}]
      self
    end

    protected 

    # @see TupleTransformOperator#_tuple2tuple
    def _tuple2tuple(tuple)
      Alf::Hash(tuple.collect{|k,v| [@renaming[k] || k, v]})
    end

  end # class Rename

  # 
  # Restrict input tuples to those for which an expression is true
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} EXPR
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This command restricts tuples to those for which EXPR evaluates
  # to true.
  #
  class Restrict < Alf::BaseOperator(__FILE__, __LINE__)

    # Hash of source -> target attribute renamings
    attr_accessor :functor

    # Builds a Rename operator instance
    def initialize
      @functor = TupleHandle.compile("true")
      yield self if block_given?
    end

    def self.functor(arg)
      case arg
        when String
          TupleHandle.compile(arg)
        when NilClass
          TupleHandle.compile("true")
        when Array
          code = arg.empty? ?
            "true" :
            arg.each_slice(2).collect{|pair| "(" + pair.join("==") + ")"}.join(" and ")
          TupleHandle.compile(code)
        when Proc
          arg
      end
    end

    # @see BaseOperator#set_args
    def set_args(args)
      @functor = Restrict.functor(args.size > 1 ? args : args.first)
      self
    end

    protected 

    # @see BaseOperator#_each
    def _each
      handle = TupleHandle.new
      each_input_tuple{|t| yield(t) if handle.set(t).evaluate(@functor) }
    end

  end # class Restrict

  # 
  # Nest some attributes as a new TUPLE-valued attribute
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} ATTR1 ATTR2 ... NEWNAME
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This operator nests attributes ATTR1 to ATTRN as a new, tuple-based
  # attribute whose name is NEWNAME
  #
  class Nest < Alf::TupleTransformOperator(__FILE__, __LINE__)

    # Array of nesting attributes
    attr_accessor :attributes

    # New name for the nested attribute
    attr_accessor :as

    # Builds a Nest operator instance
    def initialize
      @attributes = []
      @as = :nested
      yield self if block_given?
    end

    # @see BaseOperator#set_args
    def set_args(args)
      @as = args.pop.to_sym
      @attributes = args.collect{|a| a.to_sym}
      self
    end

    protected 

    # @see TupleTransformOperator#_tuple2tuple
    def _tuple2tuple(tuple)
      others = Alf::Hash((tuple.keys - @attributes).collect{|k| [k,tuple[k]]})
      others[as] = Alf::Hash(attributes.collect{|k| [k, tuple[k]]})
      others
    end

  end # class Nest

  # 
  # Unnest a TUPLE-valued attribute
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} ATTR
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This operator unnests a tuple-valued attribute ATTR so as to 
  # flatten it pairs with 'upstream' tuple.
  #
  class Unnest < Alf::TupleTransformOperator(__FILE__, __LINE__)

    # Name of the attribute to unnest
    attr_accessor :attribute

    # Builds a Rename operator instance
    def initialize
      @attribute = "nested"
      yield self if block_given?
    end

    # @see BaseOperator#set_args
    def set_args(args)
      @attribute = args.last.to_sym
      self
    end

    protected 

    # @see TupleTransformOperator#_tuple2tuple
    def _tuple2tuple(tuple)
      tuple = tuple.dup
      nested = tuple.delete(@attribute) || {}
      tuple.merge(nested)
    end

  end # class Unnest

  # 
  # Group some attributes as a new RELATION-valued attribute
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} ATTR1 ATTR2 ... NEWNAME
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This operator groups attributes ATTR1 to ATTRN as a new, relation-values
  # attribute whose name is NEWNAME
  #
  class Group < Alf::BaseOperator(__FILE__, __LINE__)

    # Attributes on which grouping applies
    attr_accessor :attributes
  
    # Attribute name for grouping tuple 
    attr_accessor :as

    # Creates a Group instance
    def initialize
      @attributes = @as = nil
      yield self if block_given?
    end

    # @see BaseOperator#set_args
    def set_args(args)
      @as = args.pop.to_sym
      @attributes = args.collect{|a| a.to_sym}
      self
    end

    protected

    # See BaseOperator#_prepare
    def _prepare
      @index = Hash.new{|h,k| h[k] = []} 
      each_input_tuple do |tuple|
        key, rest = split_tuple(tuple)
        @index[key] << rest
      end
      self
    end

    # See BaseOperator#_each
    def _each
      @index.each_pair do |k,v|
        yield(k.merge(@as => v))
      end
    end

    def split_tuple(tuple)
      key, rest = tuple.dup, {}
      @attributes.each do |a|
        rest[a] = tuple[a]
        key.delete(a)
      end
      [key,rest]
    end

  end # class Group

  # 
  # Ungroup a RELATION-valued attribute
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} ATTR
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This operator ungroup the relation-valued attribute whose
  # name is ATTR
  #
  class Ungroup < Alf::BaseOperator(__FILE__, __LINE__)

    # Relation-value attribute to ungroup
    attr_accessor :attribute
  
    # Creates a Group instance
    def initialize
      @attribute = :grouped
      yield self if block_given?
    end

    # @see BaseOperator#set_args
    def set_args(args)
      @attribute = args.pop.to_sym
      self
    end

    protected 

    # See BaseOperator#_each
    def _each
      each_input_tuple do |tuple|
        tuple = tuple.dup
        subrel = tuple.delete(@attribute)
        subrel.each do |subtuple|
          yield(tuple.merge(subtuple))
        end
      end
    end

  end # class Ungroup

  # 
  # Sort input tuples in memory and output them sorted
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} ATTR1 ATTR2...
  #
  # OPTIONS
  # #{summarized_options}
  #
  # DESCRIPTION
  #
  # This operator sorts input tuples on ATTR1 then ATTR2, etc.
  # and outputs them sorted after that.
  #
  class Sort < Alf::BaseOperator(__FILE__, __LINE__)

    attr_reader :attributes
    attr_accessor :direction

    def initialize
      @attributes = []
      @direction = :asc
      yield self if block_given?
    end

    options do |opt|
      opt.on('-r', '--reverse', "Sort in descending order"){
        @direction = :desc
      }
    end

    def attributes=(attrs)
      @attributes = attrs
    end

    def set_args(args)
      self.attributes = args.collect{|c| c.to_sym}
      self
    end

    protected 

    def compare(t1,t2)
      @attributes.each do |a|
        ac = (t1[a] <=> t2[a])
        return ac unless ac == 0
      end
      return 0
    end

    def _each
      tuples = input.to_a
      if @direction == :asc
        tuples.sort!{|k1,k2| compare(k1,k2)}
      else
        tuples.sort!{|k1,k2| compare(k2,k1)}
      end
      tuples.each(&Proc.new)
    end

  end # class Sort

  # 
  # Render input tuples with a given strategy
  #
  # SYNOPSIS
  #   #{program_name} #{command_name}
  #
  # OPTIONS
  # #{summarized_options}
  #
  class Render < Alf::Command(__FILE__, __LINE__)

    options do |opt|
      @output = :ruby
      opt.on("--ruby", "Render as ruby hashes"){ @output = :ruby }
      opt.on("--text", "Render as a text table"){ @output = :text }
      opt.on("--yaml", "Render as yaml"){ @output = :yaml }
      opt.on("--plot", "Render as a plot"){ @output = :plot }
    end

    def output(res)
      case @output
        when :text
          Renderer::Text.render(res.to_a, $stdout)
        when :yaml
          require 'yaml'
          $stdout << res.to_a.to_yaml
        when :plot
          Renderer::Plot.render(res.to_a, $stdout)
        when :ruby
          res.each{|t| $stdout << t.inspect << "\n"}
      end
    end

    def execute(args)
      output HashReader.new.pipe($stdin)
    end

  end # class Render

  # 
  # Show help about a specific command
  #
  # SYNOPSIS
  #   #{program_name} #{command_name} COMMAND
  #
  class Help < Alf::Command(__FILE__, __LINE__)
    
    # Let NoSuchCommandError be passed to higher stage
    no_react_to Quickl::NoSuchCommand
    
    # Command execution
    def execute(args)
      if args.size != 1
        puts super_command.help
      else
        cmd = has_command!(args.first, super_command)
        puts cmd.help
      end
    end
    
  end # class Help

  ##############################################################################
  #
  # PART III - Writers
  #
  # Writers are dataflow elements at the output boundary with the outside world.
  # They typically convert Enumerable tuple streams as IO output streams. All
  # writers should follow the basis given by TupleWriter.
  #
  
  #
  # Marker for chain elements converting tuple streams
  #
  module TupleWriter
    include Pipeable

    #
    # Executes the writing, outputting the resulting relation. 
    #
    # This method must be implemented by subclasses.
    #
    def execute(output = $stdout)
    end

  end # module TupleWriter

  #
  # Implements the TupleWriter contract through inspect
  #
  class HashWriter 
    include TupleWriter

    # @see TupleWriter#execute
    def execute(output = $stdout)
      each_input_tuple do |tuple|
        output << tuple.inspect << "\n"
      end
    end

  end # class HashWriter

end # class Alf
require "alf/renderer/text"
require "alf/renderer/plot"

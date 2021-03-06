module Alf
  class Adapter
    class Connection

      def initialize(conn_spec)
        @conn_spec = conn_spec
      end
      attr_reader :conn_spec

      ### connection, transaction, locks

      # Yields the block in a transaction
      def in_transaction(opts = {})
        yield
      end

      # Closes the connection
      def close
        @closed = true
      end

      # Checks whether the connection is closed
      def closed?
        defined?(@closed) && @closed
      end

      ### schema methods

      # Returns true if `name` is known, false otherwise.
      def knows?(name)
        false
      end

      # Returns the heading of a given named variable
      def heading(name)
        raise NotSupportedError, "Unable to serve heading of `#{name}` in `#{self}`"
      end

      # Returns the keys of a given named variable
      def keys(name)
        raise NotSupportedError, "Unable to serve keys of `#{name}` in `#{self}`"
      end

      # Migrate the undelrying database according to adapter semantics.
      def migrate!(opts)
        raise NotSupportedError, "Unable to migrate using `#{self}`"
      end

      ### read-only methods

      # Returns a base cog for the compilation of `expr` inside the compilation
      # plan `plan`. `expr` is guaranteed to be a `Algebra::Operand::Named`.
      def cog(plan = nil, expr = nil)
        raise NotSupportedError, "Unable to serve cog `#{expr}` in `#{self}`"
      end

      ### update methods

      # Locks the table with name `name`
      def lock(name, mode)
        yield
      end

      # Inserts `tuples` in the relvar called `name`
      def insert(name, tuples)
        raise NotSupportedError, "Unable to insert in `#{self}`"
      end

      # Delete from the relvar called `name`
      def delete(name, predicate)
        raise NotSupportedError, "Unable to delete in `#{self}`"
      end

      # Updates the relvar called `name`
      def update(name, computation, predicate)
        raise NotSupportedError, "Unable to update in `#{self}`"
      end

    end # class Connection
  end # class Adapter
end # module Alf
require_relative 'connection/schema_cached'

module Alf
  module Algebra
    module Operand
      class Fake
        include Operand

        def initialize(connection = nil, cog = nil)
          @connection = connection
          @attributes = {}
          @cog = cog
        end
        attr_accessor :connection

        def with_connection(conn)
          dup.tap{|d| d.connection = conn }
        end

        def with_heading(h)
          dup.set!(:heading => Alf::Heading.coerce(h))
        end

        def with_keys(*keys)
          dup.set!(:keys => Alf::Keys.coerce(keys))
        end

        def with_name(name)
          dup.set!(:name => name.to_sym)
        end

        def each
        end

        def name
          @attributes[:name] || "a_fake_operand"
        end

        def heading
          @attributes[:heading] || (connection && connection.heading(name)) || super
        end

        def keys
          @attributes[:keys] || Keys::EMPTY
        end

        def to_relvar
          if connection && name
            Operand::Named.new(name, connection).to_relvar
          else
            Relvar::Fake.new(self, heading)
          end
        end

        def to_cog(plan = nil)
          @cog || Engine::Leaf.new([], self)
        end

        def to_s
          name.to_s
        end

        def to_lispy
          name
        end

      protected

        def set!(h)
          @attributes.merge!(h)
          self
        end

      end # class Fake
    end # module Operand
  end # module Support
end # module Alf
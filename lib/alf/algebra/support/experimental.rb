module Alf
  module Algebra
    #
    # Marker for experimental operators
    #
    module Experimental

      class << self
        include Support::Registry

        def included(mod)
          super
          register(mod, Experimental)
        end
      end

    end # module Experimental
  end # module Algebra
end # module Alf

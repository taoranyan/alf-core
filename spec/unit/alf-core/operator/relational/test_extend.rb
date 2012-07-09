require 'spec_helper'
module Alf
  module Operator::Relational
    describe Extend do

      let(:operator_class){ Extend }

      it_should_behave_like("An operator class")

      subject{ a_lispy.extend([], :big => lambda{ tested > 10 }) }

      it{ should be_a(Extend) }

    end
  end
end

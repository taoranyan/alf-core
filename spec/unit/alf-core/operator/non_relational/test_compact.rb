require 'spec_helper'
module Alf
  module Operator::NonRelational
    describe Compact do

      let(:operator_class){ Compact }

      it_should_behave_like("An operator class")

      subject{ a_lispy.compact([]) }

      it { should be_a(Compact) }

    end
  end
end

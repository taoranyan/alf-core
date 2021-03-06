require 'spec_helper'
module Alf
  module Algebra
    describe Intersect do

      let(:operator_class){ Intersect }

      it_should_behave_like("An operator class")

      subject{ a_lispy.intersect(an_operand, an_operand) }

      it { should be_a(Intersect) }

    end
  end
end

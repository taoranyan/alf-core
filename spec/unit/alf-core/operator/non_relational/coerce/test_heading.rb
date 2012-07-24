require 'spec_helper'
module Alf
  module Operator::NonRelational
    describe Coerce, 'heading' do

      let(:operand){
        operand_with_heading(:id => String, :name => String)
      }

      subject{ op.heading }

      let(:op){ 
        a_lispy.coerce(operand, :id => Integer)
      }
      let(:expected){
        Heading[:id => Integer, :name => String]
      }

      it { should eq(expected) }

    end
  end
end

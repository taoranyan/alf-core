require 'spec_helper'
module Alf
  module Operator::Relational
    describe Rank, 'heading' do

      let(:operand){
        operand_with_heading(:id => Integer, :name => String)
      }
      let(:op){ 
        a_lispy.rank(operand, [[:name, :asc]], :rank)
      }

      subject{ op.heading }

      let(:expected){
        Heading[:id => Integer, :name => String, :rank => Integer]
      }

      it { should eq(expected) }

    end
  end
end
require 'spec_helper'
module Alf
  module Operator::Relational
    describe Wrap, 'wrap' do

      subject{ op.keys }

      let(:operand){
        an_operand.with_heading(:id => Integer, :name => String).with_keys([:id])
      }

      context 'when no key is wrapped' do
        let(:op){ 
          a_lispy.wrap(operand, [:name], :names)
        }

        it{ should eq([ AttrList[:id] ]) }
      end

      context 'when no key is wrapped (--allbut)' do
        let(:op){ 
          a_lispy.wrap(operand, [:id], :names, :allbut => true)
        }

        it{ should eq([ AttrList[:id] ]) }
      end

      context 'when a key is fully wrapped' do
        let(:op){ 
          a_lispy.wrap(operand, [:id, :name], :supplier)
        }

        it{ should eq([ AttrList[:supplier] ]) }
      end

      context 'when a key is partially wrapped' do
        let(:operand){
          an_operand.with_heading(:id => Integer, :name => String, :status => Integer).with_keys([:id, :name])
        }
        let(:op){ 
          a_lispy.wrap(operand, [:name, :status], :supplier)
        }

        it{ should eq([ AttrList[:id, :supplier] ]) }
      end

    end
  end
end

require 'spec_helper'
module Alf
  module Lang
    describe Lispy, "Relation(...)" do

      let(:lispy){ Database.examples.lispy }

      subject{ lispy.Relation(*args) }

      describe 'on a single tuple' do
        let(:args){ [{:name => "Alf"}] }
        it{ should eq(Relation[*args]) }
      end

      describe 'on two tuples' do
        let(:args){ [{:name => "Alf"}, {:name => "Lispy"}] }
        it{ should eq(Relation[*args]) }
      end

      describe 'on a Symbol' do
        let(:args){ [:suppliers] }
        specify{
          subject.should eq(lispy.database.dataset(:suppliers).to_rel)
        }
      end

    end
  end
end
require 'spec_helper'
module Alf
  describe Selection, ".coerce" do

    subject{ Selection.coerce(arg) }

    before do
      subject.should be_a(Selection)
    end

    let(:expected){
      Selection.new([ Selector.new(:name), Selector.new(:city) ])
    }

    context 'on an array of strings' do
      let(:arg){ ["name", "city"] }

      it { should eq(expected) }
    end

    context 'on an array of strings with composite selections' do
      let(:arg){ ["name", "city.name"] }

      let(:expected){
        Selection.new([ Selector.new(:name), Selector.new([:city, :name]) ])
      }

      it { should eq(expected) }
    end

    context 'on an array of symbols' do
      let(:arg){ [:name, :city] }

      it { should eq(expected) }
    end

  end
end

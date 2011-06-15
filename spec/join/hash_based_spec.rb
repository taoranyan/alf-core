require File.expand_path('../../spec_helper', __FILE__)
class Alf
  describe Join::HashBased do
      
    let(:suppliers) {[
      {:sid => 'S1', :city => 'London'},
      {:sid => 'S2', :city => 'Paris'},
      {:sid => 'S3', :city => 'Paris'}
    ]}

    let(:statuses) {[
      {:sid => 'S1', :status => 20},
      {:sid => 'S2', :status => 10},
      {:sid => 'S3', :status => 30}
    ]}

    let(:countries) {[
      {:city => 'London',    :country => 'England'},
      {:city => 'Paris',     :country => 'France'},
      {:city => 'Bruxelles', :country => 'Belgium (until ?)'}
    ]}

    let(:operator){ Join::HashBased.new }
    subject{ operator.to_a }

    describe "when applied on both candidate keys" do
      before{ operator.input = [suppliers, statuses] }
      let(:expected){[
        {:sid => 'S1', :city => 'London', :status => 20},
        {:sid => 'S2', :city => 'Paris', :status => 10},
        {:sid => 'S3', :city => 'Paris', :status => 30}
      ]}
      it { should == expected }
    end
    
    describe "when applied on a typical foreign key" do
      let(:expected){[
        {:sid => 'S1', :city => 'London', :country => 'England'},
        {:sid => 'S2', :city => 'Paris',  :country => 'France'},
        {:sid => 'S3', :city => 'Paris',  :country => 'France'}
      ]}
      describe "on one way" do
        before{ operator.input = [suppliers, countries] }
        it { should == expected }
      end
      describe "on the other way around" do
        before{ operator.input = [countries, suppliers] }
        it { should == expected }
      end
    end

  end 
end

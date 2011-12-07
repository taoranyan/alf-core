require 'spec_helper'
module Alf
  describe TupleExpression do

    describe "the class itself" do
      let(:type){ TupleExpression }
      def TupleExpression.exemplars
        [
          "10",
          "status > 10",
        ].map{|x| TupleExpression.coerce(x)}
      end
      it_should_behave_like 'A valid type implementation'
    end

    it "should include a valid example" do
      expr = TupleExpression["status * 10"]
      expr.call(:status => 20).should eq(200)
    end

    let(:handle) {
      Tools::TupleHandle.new.set(:status => 10)
    }

    describe "coerce" do

      subject{ TupleExpression.coerce(arg) }

      describe "with nil" do
        let(:arg){ nil }
        specify{ lambda{ subject }.should raise_error(ArgumentError) }
      end

      describe "with a String" do
        let(:arg){ "true" }
        it { should be_a(TupleExpression) }
        specify{ 
          subject.evaluate(handle).should eql(true) 
          subject.source.should eq("true")
        }
      end

      describe "with a Symbol" do
        let(:arg){ :status }
        it { should be_a(TupleExpression) }
        specify{ 
          subject.evaluate(handle).should eql(10) 
          subject.source.should eq(:status)
        }
      end

      describe "with a Proc" do
        let(:arg){ lambda{ :hello } }
        it { should be_a(TupleExpression) }
        specify{ 
          subject.evaluate(handle).should eql(:hello) 
          subject.source.should be_nil
        }
      end

    end # coerce

    describe "from_argv" do

      subject{ TupleExpression.from_argv(argv) }

      describe "with a String (1)" do
        let(:argv){ %w{true} }
        it { should be_a(TupleExpression) }
        specify{ 
          subject.evaluate(handle).should eql(true) 
          subject.source.should eq("true")
        }
      end

      describe "with a String (2)" do
        let(:argv){ ["status > 10"] }
        it { should be_a(TupleExpression) }
        specify{ 
          subject.evaluate(handle).should eql(false) 
          subject.source.should eq("status > 10")
        }
      end

      describe "with two String" do
        let(:argv){ %w{hello world} }
        specify{ lambda{subject}.should raise_error(ArgumentError) }
      end

    end # from_argv

    describe 'call' do
      let(:expr){ TupleExpression["status > 10"] }

      it 'should build its handle correctly' do
        expr.call(:status => 20).should be_true
        expr.call(:status => 5).should be_false
      end

      it 'should be aliased ad []' do
        expr[:status => 20].should be_true
        expr[:status => 5].should be_false
      end

    end # call

    describe 'to_ruby_literal' do

      it 'should work when code is known' do
        expr = TupleExpression["status > 10"]
        expr.to_ruby_literal.should eq('Alf::TupleExpression["status > 10"]')
      end

      it 'should raise a NotImplementedError if no source code' do
        expr = TupleExpression[lambda{status > 10}]
        lambda{ expr.to_ruby_literal }.should raise_error(NotImplementedError)
      end

    end # to_ruby_literal

  end # TupleExpression
end # Alf
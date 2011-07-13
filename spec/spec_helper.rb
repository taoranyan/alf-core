$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'alf'

Alf::Lispy.extend(Alf::Lispy)

shared_examples_for "An operator class" do

  it "should not have public set_args, _each and _prepare methods" do
    operator_class.public_method_defined?(:set_args).should be_false
    operator_class.public_method_defined?(:_each).should be_false
    operator_class.public_method_defined?(:_prepare).should be_false
  end

  it "should have a public run method" do
    operator_class.public_method_defined?(:run).should be_true
  end
  
  it "should have a public pipe method" do
    operator_class.public_method_defined?(:pipe).should be_true
  end

  it "should have a public each method" do
    operator_class.public_method_defined?(:each).should be_true
  end
  
  it "should have a unary? class method" do
    operator_class.should respond_to(:unary?)
  end

  it "should have a binary? class method" do
    operator_class.should respond_to(:binary?)
  end
  
  it "should implement unary? and binary? accurately" do
    operator_class.unary?.should_not eq(operator_class.binary?)
    operator_class.unary?.should eq(operator_class.ancestors.include?(Alf::Operator::Unary))
    operator_class.binary?.should eq(operator_class.ancestors.include?(Alf::Operator::Binary))
  end

end

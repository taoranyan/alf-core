require 'spec_helper'
module Alf
  module Tools
    describe Signature, '#option_parser' do

      let(:signature){
        Signature.new do |s|
          s.option :allbut, Boolean,  true
          s.option :name,   AttrName, :autonum
        end
      }
      let(:clazz){ Class.new(Object) }
      let(:receiver){ clazz.new }
      before{ signature.install(clazz) }
      subject{ signature.option_parser(receiver) }

      specify "expected" do
        opt = OptionParser.new 
        opt.on("--allbut"){ receiver.send(:allbut=,true) }
        opt.on("--name=NAME"){|val| receiver.send(:name=,val) }
        opt.parse!(["--allbut","--name=world"])
        receiver.allbut.should be_true
        receiver.name.should eq(:world)
      end

      it { should be_a(OptionParser) }

      it "should install option values correctly" do
        subject.parse!(["--allbut","--name=world"])
        receiver.allbut.should be_true
        receiver.name.should eq(:world)
      end

    end
  end
end
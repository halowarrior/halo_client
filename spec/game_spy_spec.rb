require 'spec_helper'
require 'securerandom'

describe Halo::GameSpy do

  describe "#challenge" do
    let(:random_bytes){ SecureRandom.random_bytes * 2 }
    
    context "with challenge argument" do
      it "returns 32 byte string" do
        random_bytes = SecureRandom.random_bytes * 2
        Halo::GameSpy.challenge(random_bytes).length.should == 32
      end
    end
    
    context "without challenge argument" do
      it 'returns 32 byte string' do
        Halo::GameSpy.challenge.length.should == 32
      end
    end
  end
  
end
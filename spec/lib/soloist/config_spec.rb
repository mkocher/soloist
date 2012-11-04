require "spec_helper"

describe Soloist::Config do
  let(:soloist_rc) { Soloist::RoyalCrown.new }
  let(:working_path) { "/yo/dawg" }
  let(:config) { Soloist::Config.new(working_path, soloist_rc) }

  describe "#solo_rb" do
    let(:solo_rb) { config.solo_rb.split("\n") }
    
    context "without extra cookbook paths" do
      it "can generate solo.rb" do
        config.solo_rb.should == 'cookbook_path "/yo/dawg/cookbooks"'
      end
    end
    
    context "with a cookbook path" do
      it "can have multiple cookbook paths" do
        soloist_rc.cookbook_paths << "/opt/holla/at/yo/soloist"
        config.solo_rb.should include 'cookbook_path "/opt/holla/at/yo/soloist"'
      end

      it "expands paths" do
        home = File.expand_path("~")
        soloist_rc.cookbook_paths << "~/yo/homes"
        config.solo_rb.should include "cookbook_path \"#{home}/yo/homes\""
      end
    end
  end

  
end

require "spec_helper"

describe Soloist::Config do
  include FakeFS::SpecHelpers

  let(:soloist_rc) { Soloist::RoyalCrown.new(:path => "/tmp/soloist/soloistrc") }
  let(:config) { Soloist::Config.new(soloist_rc) }

  before do
    # set up (fake) directories
    FileUtils.mkdir_p("/tmp/soloist/cookbooks")
    FileUtils.mkdir_p("/tmp/soloist/meth/cookbooks")
    FileUtils.mkdir_p("/opt/holla/at/yo/soloist")
    FileUtils.mkdir_p("#{ENV['HOME']}/yo/homes")
  end

  describe "#as_solo_rb" do
    context "without extra cookbook paths" do
      it "can generate solo.rb" do
        config.as_solo_rb.should == 'cookbook_path ["/tmp/soloist/cookbooks"]'
      end
    end

    context "with a cookbook path" do
      before { soloist_rc.cookbook_paths = ["/opt/holla/at/yo/soloist"] }

      it "can have multiple cookbook paths" do
        config.as_solo_rb.should == 'cookbook_path ["/tmp/soloist/cookbooks", "/opt/holla/at/yo/soloist"]'
      end

      it "removes duplicate cookbook paths" do
        expect do
          soloist_rc.cookbook_paths << "/opt/holla/at/yo/soloist"
        end.not_to change { config.as_solo_rb }
      end
    end

    context "with a cookbook path to a non-existent directory" do
      before { soloist_rc.cookbook_paths = ["/some/bogus/path"] }

      it "prunes the config of the empty path" do
        File.should_not exist("/some/bogus/path")
        config.as_solo_rb.should == 'cookbook_path ["/tmp/soloist/cookbooks"]'
      end
    end

    context "with relative paths" do
      let(:pwd) { File.expand_path(".") }

      before { soloist_rc.cookbook_paths << "./meth/cookbooks" }

      it "can have multiple cookbook paths" do
        config.as_solo_rb.should == 'cookbook_path ["/tmp/soloist/cookbooks", "/tmp/soloist/meth/cookbooks"]'
      end
    end

    context "with unixisms in the cookbook path" do
      let(:home) { File.expand_path("~") }

      before { soloist_rc.cookbook_paths << "~/yo/homes" }

      it "expands paths" do
        config.as_solo_rb.should include "#{home}/yo/homes"
      end
    end
  end

  describe "#as_json" do
    context "with recipes" do
      before { soloist_rc.recipes = ["waffles"] }

      it "can generate json" do
        config.as_json["recipes"].should include "waffles"
      end
    end
  end

  describe "#compiled_rc" do
    let(:switch) { {"OX_TONGUES" => {"FINE" => {"recipes" => ["hobo_fist"]}}} }

    before do
      soloist_rc.env_variable_switches =  switch
    end

    context "when a switch is active" do
      before { ENV.stub(:[]).and_return("FINE") }

      it "merges the environment variable switch" do
        config.compiled_rc.recipes.should include "hobo_fist"
      end
    end

    context "when a switch is inactive" do
      before { ENV.stub(:[]).and_return("WHAT_NO_EW") }

      it "outputs an empty list" do
        config.compiled_rc.recipes.should be_empty
      end
    end

    context "when switches are nested" do
      let(:inner) { {"GOAT" => {"TASTY" => {"node_attributes" => {"bbq" => "satan"}}}} }
      let(:outer) { {"recipes" => ["stinkditch"], "env_variable_switches" => inner} }

      before { ENV.stub(:[]).and_return("TASTY") }

      context "when the inner switch is active" do
        let(:switch) { {"HORSE" => {"TASTY" => outer }} }

        it "evalutes all switches" do
          config.compiled_rc.node_attributes.bbq.should == "satan"
          config.compiled_rc.recipes.should == ["stinkditch"]
        end
      end

      context "when the outer switch is inactive" do
        let(:switch) { {"HORSE" => {"GROSS" => outer }} }

        it "does not evaluate deeper" do
          config.compiled_rc.recipes.should be_empty
          config.compiled_rc.node_attributes.should be_empty
        end
      end
    end
  end

  describe "#merge!" do
    let(:soloist_rc) { Soloist::RoyalCrown.new(:recipes => ["guts"], :node_attributes => {:reliable => "maybe"}) }
    let(:other_rc) { Soloist::RoyalCrown.new(:recipes => ["chum"], :node_attributes => {:tasty => "maybe"}) }
    let(:other_config) { Soloist::Config.new(other_rc) }

    it "merges another config into the current one" do
      config.merge!(other_config)
      config.royal_crown.recipes.should =~ ["guts", "chum"]
      config.royal_crown.node_attributes.keys.should =~ [:reliable, :tasty]
    end

    it "does not trample the other config" do
      config.merge!(other_config)
      other_config.royal_crown.recipes.should =~ ["chum"]
      other_config.royal_crown.node_attributes.should == {:tasty => "maybe"}
    end
  end
end

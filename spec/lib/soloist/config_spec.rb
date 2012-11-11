require "spec_helper"

describe Soloist::Config do
  let(:soloist_rc) { Soloist::RoyalCrown.new }
  let(:config) { Soloist::Config.new("/yo/dawg", soloist_rc) }

  describe "#as_solo_rb" do
    context "without extra cookbook paths" do
      it "can generate solo.rb" do
        config.as_solo_rb.should have(1).thing
        config.as_solo_rb.should == ['cookbook_path "/yo/dawg/cookbooks"']
      end
    end

    context "with a cookbook path" do
      before { soloist_rc.cookbook_paths = ["/opt/holla/at/yo/soloist"] }

      it "can have multiple cookbook paths" do
        config.as_solo_rb.should have(2).things
        config.as_solo_rb.should include 'cookbook_path "/opt/holla/at/yo/soloist"'
      end

      it "removes duplicate cookbook paths" do
        expect do
          soloist_rc.cookbook_paths << "/opt/holla/at/yo/soloist"
        end.not_to change { config.as_solo_rb.count }
      end
    end

    context "with relative paths" do
      let(:pwd) { File.expand_path(".") }

      before { soloist_rc.cookbook_paths << "./meth/cookbooks" }

      it "can have multiple cookbook paths" do
        config.as_solo_rb.should include "cookbook_path \"#{pwd}/meth/cookbooks\""
      end
    end

    context "with unixisms in the cookbook path" do
      let(:home) { File.expand_path("~") }

      before { soloist_rc.cookbook_paths << "~/yo/homes" }

      it "expands paths" do
        config.as_solo_rb.should include "cookbook_path \"#{home}/yo/homes\""
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

  describe "#as_env" do
    before { ENV.stub(:[]).and_return("supernuts") }

    Soloist::Config::PROPAGATED_ENV.each do |variable|
      it "propagates #{variable}" do
        config.as_env[variable].should == "supernuts"
      end
    end

    it "propagates env_variable_switches keys" do
      soloist_rc.env_variable_switches = {"MONKEY_BRAINS" => "sure"}
      config.as_env["MONKEY_BRAINS"].should == "supernuts"
    end

    it "removes empty environment variables" do
      ENV.should_receive(:[]).with("TOE_FUNGUS").and_return(nil)
      soloist_rc.env_variable_switches = {"TOE_FUNGUS" => "hooray"}
      config.as_env.keys.should_not include "TOE_FUNGUS"
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
end

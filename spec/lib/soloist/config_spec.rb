require "spec_helper"

describe Soloist::Config do
  let(:tempdir) { Dir.mktmpdir }
  let(:soloist_rc_path) { File.expand_path("soloistrc", tempdir) }
  let(:soloist_rc) { Soloist::RoyalCrown.new(:path => soloist_rc_path) }
  let(:config) { Soloist::Config.new(soloist_rc) }
  let(:cookbook_path) { File.expand_path("cookbooks", tempdir) }
  let(:nested_cookbook_path) { File.expand_path("whoa/cookbooks", tempdir) }

  describe "#as_solo_rb" do
    context "when the default cookbook path does not exist" do
      it "does not point to any cookbook paths" do
        config.as_solo_rb.should == 'cookbook_path []'
      end
    end

    context "when the default cookbook path exists" do
      before { FileUtils.mkdir_p(cookbook_path) }

      it "points to the default cookbook path" do
        config.as_solo_rb.should == %(cookbook_path ["#{cookbook_path}"])
      end

      context "with a specified cookbook path" do
        before { soloist_rc.cookbook_paths = [nested_cookbook_path] }

        context "when the specified path exists" do
          before { FileUtils.mkdir_p(nested_cookbook_path) }

          it "can have multiple cookbook paths" do
            config.as_solo_rb.should == %(cookbook_path ["#{cookbook_path}", "#{nested_cookbook_path}"])
          end

          context "with duplicate cookbook paths" do
            it "ignores duplicate entries" do
              expect do
                soloist_rc.cookbook_paths << nested_cookbook_path
              end.not_to change { config.as_solo_rb }
            end

            it "ignores the default cookbook path" do
              expect do
                soloist_rc.cookbook_paths << cookbook_path
              end.not_to change { config.as_solo_rb }
            end
          end
        end

        context "when the specified path does not exist" do
          it "only points to default cookbook path" do
            config.as_solo_rb.should == %(cookbook_path ["#{cookbook_path}"])
          end
        end
      end
    end

    context "with relative paths" do
      before do
        soloist_rc.cookbook_paths << "./whoa/cookbooks"
        FileUtils.mkdir_p(nested_cookbook_path)
      end

      it "can have multiple cookbook paths" do
        config.as_solo_rb.should == %(cookbook_path ["#{nested_cookbook_path}"])
      end
    end

    context "with unixisms in the cookbook path" do
      let(:home) { File.expand_path("~") }

      before { soloist_rc.cookbook_paths = ["~"] }

      it "expands paths" do
        config.as_solo_rb.should == %(cookbook_path ["#{home}"])
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

require "spec_helper"

describe Soloist::Config do
  let(:tempdir) { Dir.mktmpdir }
  let(:soloist_rc_path) { File.expand_path("soloistrc", tempdir) }
  let(:soloist_rc) { Soloist::RoyalCrown.new(:path => soloist_rc_path) }
  let(:config) { Soloist::Config.new(soloist_rc) }
  let(:cookbook_path) { File.expand_path("cookbooks", tempdir) }
  let(:nested_cookbook_path) { File.expand_path("whoa/cookbooks", tempdir) }

  describe "#solo_rb" do
    subject { config.solo_rb.tap { |f| f.rewind }.read }

    context "when the default cookbook path does not exist" do
      it { should == 'cookbook_path []' }
    end

    context "when the default cookbook path exists" do
      before { FileUtils.mkdir_p(cookbook_path) }

      it { should == %(cookbook_path ["#{cookbook_path}"]) }

      context "when the default cookbook path is specified" do
        before { soloist_rc.cookbook_paths << cookbook_path }

        it { should == %(cookbook_path ["#{cookbook_path}"]) }
      end

      context "with a specified cookbook path" do
        before { soloist_rc.cookbook_paths = [nested_cookbook_path] }

        context "when the specified path exists" do
          before { FileUtils.mkdir_p(nested_cookbook_path) }

          it { should == %(cookbook_path ["#{cookbook_path}", "#{nested_cookbook_path}"]) }

          context "with duplicate cookbook paths" do
            before { soloist_rc.cookbook_paths << nested_cookbook_path }

            it { should == %(cookbook_path ["#{cookbook_path}", "#{nested_cookbook_path}"]) }
          end
        end

        context "when the specified path does not exist" do
          it { should == %(cookbook_path ["#{cookbook_path}"]) }
        end
      end
    end

    context "with relative paths" do
      before do
        soloist_rc.cookbook_paths = ["./whoa/cookbooks"]
        FileUtils.mkdir_p(nested_cookbook_path)
      end

      it { should == %(cookbook_path ["#{nested_cookbook_path}"]) }
    end

    context "with unixisms in the cookbook path" do
      let(:home) { File.expand_path("~") }

      before { soloist_rc.cookbook_paths = ["~"] }

      it { should == %(cookbook_path ["#{home}"]) }
    end
  end

  describe "#node_json" do
    let(:node_json) { JSON.parse(config.node_json.tap{ |f| f.rewind }.read) }

    context "with recipes" do
      before { soloist_rc.recipes = ["waffles"] }

      it "can generate json" do
        node_json["recipes"].should include "waffles"
      end
    end

    context "with an environment switch" do
      let(:nested) { {} }
      let(:switch) do
        {
          "TONGUES" => {
            "FINE" => {
              "recipes" => ["hobo_fist"],
              "env_variable_switches" => nested
            }
          }
        }
      end

      before { config.royal_crown.env_variable_switches = switch }

      context "when the switch is inactive" do
        before { ENV.stub(:[]).and_return("LOLWUT") }

        it "does not merge the attribute" do
          node_json["recipes"].should be_empty
        end
      end

      context "when a switch is active" do
        before { ENV.stub(:[]).and_return("FINE") }

        it "merges the attributes" do
          node_json["recipes"].should =~ ["hobo_fist"]
        end

        context "when an inactive switch is nested" do
          let(:nested) { {"BEANS" => {"EW" => {"recipes" => ["slammin"]}}} }

          it "does not merge the attributes" do
            node_json["recipes"].should =~ ["hobo_fist"]
          end
        end

        context "when an active switch is nested" do
          let(:nested) { {"BEANS" => {"FINE" => {"recipes" => ["slammin"]}}} }

          it "merges the attributes" do
            node_json["recipes"].should =~ ["slammin"]
          end
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

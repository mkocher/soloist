require "spec_helper"

RSpec.describe Soloist::Config do
  let(:soloist_rc_path) { File.expand_path("soloistrc", RSpec.configuration.tempdir) }
  let(:soloist_rc) { Soloist::RoyalCrown.new(:path => soloist_rc_path) }
  let(:config) { Soloist::Config.new(soloist_rc) }
  let(:cookbook_path) { File.expand_path("cookbooks", RSpec.configuration.tempdir) }
  let(:nested_cookbook_path) { File.expand_path("whoa/cookbooks", RSpec.configuration.tempdir) }

  describe "#as_solo_rb" do
    subject { config.as_solo_rb }

    it { should include 'file_cache_path "/var/chef/cache"' }
    it { should include %(json_attribs "#{config.node_json_path}") }
  end

  describe "#cookbook_paths" do
    subject { config.cookbook_paths }

    context "when the default cookbook path does not exist" do
      it "should have no paths" do
        expect(subject.size).to eq(0)
      end
    end

    context "when the default cookbook path exists" do
      before { FileUtils.mkdir_p(cookbook_path) }

      it "should have one path" do
        expect(subject.size).to eq(1)
      end
      it { is_expected.to match_array([cookbook_path]) }

      context "when the default cookbook path is specified" do
        before { soloist_rc.cookbook_paths = [cookbook_path] }

        it "should have one path" do
          expect(subject.size).to eq(1)
        end
        it { is_expected.to match_array([cookbook_path]) }
      end

      context "with a specified cookbook path" do
        before { soloist_rc.cookbook_paths = [nested_cookbook_path] }

        context "when the specified path exists" do
          before { FileUtils.mkdir_p(nested_cookbook_path) }

          it "should have two path" do
            expect(subject.size).to eq(2)
          end
          it { is_expected.to match_array([cookbook_path, nested_cookbook_path]) }

          context "with duplicate cookbook paths" do
            before { soloist_rc.cookbook_paths = [nested_cookbook_path, nested_cookbook_path] }

            it "should have two path" do
              expect(subject.size).to eq(2)
            end
            it { is_expected.to match_array([cookbook_path, nested_cookbook_path]) }
          end
        end

        context "when the specified path does not exist" do
          it "should have one path" do
            expect(subject.size).to eq(1)
          end
          it { is_expected.to match_array([cookbook_path]) }
        end
      end
    end

    context "with relative paths" do
      before do
        soloist_rc.cookbook_paths = ["./whoa/cookbooks"]
        FileUtils.mkdir_p(nested_cookbook_path)
      end

      it "should have one path" do
        expect(subject.size).to eq(1)
      end
      it { is_expected.to match_array([nested_cookbook_path]) }
    end

    context "with unixisms in the cookbook path" do
      let(:home) { File.expand_path("~") }

      before { soloist_rc.cookbook_paths = ["~"] }

      it "should have one path" do
        expect(subject.size).to eq(1)
      end
      it { is_expected.to match_array([home]) }
    end
  end

  describe "#as_node_json" do
    let(:soloist_rc) do
      Soloist::RoyalCrown.new(
        :path => soloist_rc_path,
        :recipes => ["waffles"],
        :node_attributes => { "gargling" => "cool", "birds" => {"nested" => "cheep"} }
      )
    end

    describe "node_attributes" do
      subject { config.as_node_json }

      it { should include "gargling" => "cool" }
      it { should include "birds" => { "nested" => "cheep" } }
    end

    describe "recipes" do
      subject { config.as_node_json["recipes"] }

      it "should have one path" do
        expect(subject.size).to eq(1)
      end
      it { is_expected.to match_array(["waffles"]) }
    end
  end

  describe "#compiled" do
    let(:nested) { {} }
    let(:switch) do
      {
        "TONGUES" => {
          "FINE" => {
            "recipes" => ["hobo_fist"],
            "cookbook_paths" => ["shell_in"],
            "node_attributes" => {
              "doc" => "absent"
            },
            "env_variable_switches" => nested
          }
        }
      }
    end

    before { config.royal_crown.env_variable_switches = switch }

    context "when the switch is inactive" do
      before { allow(ENV).to receive(:[]).and_return("LOLWUT") }

      it "does not merge the attribute" do
        expect(config.compiled["recipes"]).to be_empty
      end
    end

    context "when a switch is active" do
      before { allow(ENV).to receive(:[]).and_return("FINE") }

      it "merges the attributes" do
        expect(config.compiled.recipes).to match_array(["hobo_fist"])
      end

      it "merges the node attributes" do
        expect(config.compiled.node_attributes).to eq("doc" => "absent")
      end

      context "when an inactive switch is nested" do
        let(:nested) { {"BEANS" => {"EW" => {"recipes" => ["slammin"]}}} }

        it "does not merge the attributes" do
          expect(config.compiled.recipes).to match_array(["hobo_fist"])
        end
      end

      context "when an active switch is nested" do
        let(:nested) { {"BEANS" => {"FINE" => {"cookbook_paths" => ["shell_out"], "recipes" => ["slammin"], "node_attributes" => {"kocher" => "present"}}}} }

        it "merges the attributes" do
          expect(config.compiled.recipes).to match_array(["slammin", "hobo_fist"])
          expect(config.compiled.cookbook_paths).to match_array(["shell_in", "shell_out"])
        end

        it "merges the node attributes" do
          expect(config.compiled.node_attributes).to eq("doc" => "absent", "kocher" => "present")
        end
      end
    end
  end

  describe "#merge!" do
    let(:soloist_rc) { Soloist::RoyalCrown.new('recipes' => ["guts"], "node_attributes" => {"reliable" => "maybe"}) }
    let(:other_rc) { Soloist::RoyalCrown.new('recipes' => ["chum"], "node_attributes" => {"tasty" => "maybe"}) }
    let(:other_config) { Soloist::Config.new(other_rc) }

    it "merges another config into the current one" do
      config.merge!(other_config)
      expect(config.royal_crown.recipes).to match_array(["guts", "chum"])
      expect(config.royal_crown.node_attributes.keys).to match_array(["reliable", "tasty"])
    end

    it "does not trample the other config" do
      config.merge!(other_config)
      expect(other_config.royal_crown.recipes).to match_array(["chum"])
      expect(other_config.royal_crown.node_attributes).to eq("tasty" => "maybe")
    end
  end

  describe "#log_level" do
    subject { config.log_level }

    context "when LOG_LEVEL is not set" do
      it { should == "info" }
    end

    context "when LOG_LEVEL is set" do
      before { allow(ENV).to receive(:[]).and_return("BEANS") }
      it { should == "BEANS" }
    end
  end

  describe "#debug?" do
    subject { config.debug? }

    context "when log_level is not debug" do
      it { should_not be }
    end

    context "when log_level is debug" do
      before { allow(config).to receive(:log_level).and_return("debug") }
      it { should be }
    end
  end
end

require "spec_helper"

describe Soloist::RoyalCrown do
  let(:royal_crown) { Soloist::RoyalCrown.new }

  context "with a file" do
    let(:contents) { { "recipes" => ["broken_vim"] } }
    let(:tempfile) do
      Tempfile.new("soloist-royalcrown").tap do |file|
        file.write(YAML.dump(contents))
        file.close
      end
    end

    let(:royal_crown) { Soloist::RoyalCrown.from_file(tempfile.path) }

    describe ".from_file" do
      context "when the rc file is empty" do
        let(:tempfile) do
          Tempfile.new("soloist-royalcrown").tap do |file|
            file.close
          end
        end

        it "loads an empty file" do
          expect { royal_crown }.not_to raise_error
        end
      end

      it "loads from a yaml file" do
        royal_crown.recipes.should =~ ["broken_vim"]
      end

      it "defaults nil fields to an empty primitive" do
        royal_crown.node_attributes.should == {}
      end
    end

    describe "#save" do
      it "writes the values to a file" do
        royal_crown.recipes = ["hot_rats", "tissue_paper"]
        royal_crown.save
        royal_crown = Soloist::RoyalCrown.from_file(tempfile.path)
        royal_crown.recipes.should =~ ["hot_rats", "tissue_paper"]
      end
    end

    describe "#to_yaml" do
      it "skips the path attribute" do
        royal_crown.to_yaml.keys.should_not include "path"
      end

      it "nils out fields that have not been set" do
        royal_crown.to_yaml["node_attributes"].should be_nil
      end
    end
  end
end

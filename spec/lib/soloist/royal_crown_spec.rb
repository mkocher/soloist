require "spec_helper"

describe Soloist::RoyalCrown do
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
      it "loads from a yaml file" do
        royal_crown.recipes.should =~ ["broken_vim"]
      end

      it "defaults nil fields to an empty primitive" do
        royal_crown.node_attributes.should == {}
      end
    end

    describe "#save" do
      it "writes the values to a file" do
        royal_crown.recipes << "tissue_paper"
        royal_crown.save
        royal_crown = Soloist::RoyalCrown.from_file(tempfile.path)
        royal_crown.recipes.should =~ ["broken_vim", "tissue_paper"]
      end
    end

    describe "#to_hash" do
      it "skips the path attribute" do
        royal_crown.to_hash.keys.should_not include "path"
      end
    end
  end

  context "without a file" do
    let(:royal_crown) { Soloist::RoyalCrown.new }

    describe "#env_variable_switches" do
      it "allows additions" do
        royal_crown.env_variable_switches["meat"] = "beans"
        royal_crown.env_variable_switches["meat"].should == "beans"
      end
    end

    describe "#to_hash" do
      it "nils out fields that have not been set" do 
        royal_crown.to_hash["recipes"].should be_nil
      end
    end
  end
end

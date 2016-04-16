require "spec_helper"

describe Soloist::RoyalCrown do
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
      expect(royal_crown.recipes).to match_array(["broken_vim"])
    end

    it "defaults nil fields to an empty primitive" do
      expect(royal_crown.node_attributes).to eq({})
    end

    context "when the rc file has ERB tags" do
      let(:tempfile) do
        Tempfile.new("soloist-royalcrown").tap do |file|
          file.write(<<-YAML
          recipes:
            - broken_vim
          node_attributes:
            evaluated: <%= "From ERB" %>
          YAML
          )
          file.close
        end
      end

      it "evaluates the ERB and parses the resulting YAML" do
        expect(royal_crown.node_attributes).to eq({
          "evaluated" => "From ERB"
        })
        expect(royal_crown.recipes).to match_array(["broken_vim"])
      end
    end
  end

  describe "#save" do
    it "writes the values to a file" do
      royal_crown.recipes = ["hot_rats", "tissue_paper"]
      royal_crown.save
      royal_crown = Soloist::RoyalCrown.from_file(tempfile.path)
      expect(royal_crown.recipes).to match_array(["hot_rats", "tissue_paper"])
    end
  end

  describe "#to_yaml" do
    it "skips the path attribute" do
      expect(royal_crown.to_yaml.keys).to_not include "path"
    end

    it "nils out fields that have not been set" do
      expect(royal_crown.to_yaml["node_attributes"]).to be_nil
    end
  end
end

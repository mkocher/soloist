require "spec_helper"

describe Soloist::Spotlight do
  let(:spotlight) { Soloist::Spotlight.new(shallow_path) }
  let(:tempdir) { Dir.mktmpdir }
  let(:shallow_path) { File.expand_path("beans/roger", tempdir) }
  let(:file_path) { File.expand_path("soloistrc", shallow_path) }

  before do
    FileUtils.mkdir_p(shallow_path)
    FileUtils.touch(file_path)
  end

  describe "#search_for" do
    it "finds a soloistrc in the current directory" do
      spotlight.search_for("soloistrc").should == file_path
    end

    context "inside a deeper directory" do
      let(:deep_path) { File.expand_path("meat/hi", shallow_path) }
      let(:spotlight) { Soloist::Spotlight.new(deep_path) }

      before { FileUtils.mkdir_p(deep_path) }

      it "finds a soloistrc upwards" do
        spotlight.search_for("soloistrc").should == file_path
      end
    end
  end
end

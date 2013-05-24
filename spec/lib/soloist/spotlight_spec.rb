require "spec_helper"

describe Soloist::Spotlight do
  let(:shallow_path) { File.expand_path("beans/roger", RSpec.configuration.tempdir) }
  let(:custom_path) { Dir.mktmpdir }
  let(:spotlight) { Soloist::Spotlight.new(shallow_path) }

  before { FileUtils.mkdir_p(shallow_path) }

  describe "#find" do
    context "with non-existent files" do
      it "raises an error with three files" do
        expect do
          begin
            spotlight.find!("larry", "moe", "curly")
          rescue Soloist::NotFound => e
            e.message.should == "Could not find larry, moe or curly"
            raise
          end
        end.to raise_error(Soloist::NotFound)
      end

      it "raises an error with two files" do
        expect do
          begin
            spotlight.find!("lulz", "wut")
          rescue Soloist::NotFound => e
            e.message.should == "Could not find lulz or wut"
            raise
          end
        end.to raise_error(Soloist::NotFound)
      end

      it "raises an error with one file" do
        expect do
          begin
            spotlight.find!("whatever.dude")
          rescue Soloist::NotFound => e
            e.message.should == "Could not find whatever.dude"
            raise
          end
        end.to raise_error(Soloist::NotFound)
      end
    end

    context "with a custom config path" do
      let(:file_path) { File.expand_path("soloistrc", custom_path) }
      let(:spotlight) { Soloist::Spotlight.new(shallow_path, :custom_path => custom_path) }

      before { FileUtils.touch(file_path) }

      it "finds a soloistrc in the current directory" do
        spotlight.find("soloistrc").to_s.should == File.join(custom_path, "soloistrc")
      end
    end

    context "when the file exists" do
      let(:file_path) { File.expand_path("soloistrc", shallow_path) }

      before { FileUtils.touch(file_path) }

      it "finds a soloistrc in the current directory" do
        spotlight.find("soloistrc").to_s.should =~ /\/beans\/roger\/soloistrc$/
      end

      context "inside a deeper directory" do
        let(:deep_path) { File.expand_path("meat/hi", shallow_path) }
        let(:spotlight) { Soloist::Spotlight.new(deep_path) }

        before { FileUtils.mkdir_p(deep_path) }

        it "finds a soloistrc upwards" do
          spotlight.find("soloistrc").to_s.should == file_path
        end
      end
    end
  end
end

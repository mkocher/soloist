require "spec_helper"

describe Soloist::CLI do
  let(:cli) { Soloist::CLI.new }
  let(:base_path) { Dir.mktmpdir }
  let(:soloistrc_path) { File.expand_path("soloistrc", base_path) }

  before { FileUtils.mkdir_p(base_path) }

  describe "#run_chef" do
    context "when the soloistrc file does not exist" do
      it "raises an error" do
        Dir.chdir(base_path) do
          expect { cli.run_chef }.to raise_error(Soloist::NotFound)
        end
      end
    end

    context "when the soloistrc file exists" do
      before do
        File.open(soloistrc_path, "w") do |file|
          file.write(YAML.dump("recipes" => ["stinky::feet"]))
        end
      end

      context "when the Cheffile does not exist" do
        it "complains about not finding the Cheffile" do
          Dir.chdir(base_path) do
            expect { cli.run_chef }.to raise_error(Errno::ENOENT)
          end
        end
      end

      context "when the Cheffile exists" do
        before do
          FileUtils.touch(File.expand_path("Cheffile", base_path))
        end

        it "runs chef" do
          cli.should_receive(:exec)
          Dir.chdir(base_path) do
            cli.run_chef
          end
        end
      end
    end
  end

  describe "#ensure_chef_cache_path" do
    context "when the cache path does not exist" do
      before { File.stub(:directory? => false) }

      it "creates the cache path" do
        cli.should_receive(:system).with("sudo mkdir -p /var/chef/cache")
        cli.ensure_chef_cache_path
      end
    end

    context "when the cache path exists" do
      before { File.stub(:directory? => true) }

      it "does not create the cache path" do
        cli.should_not_receive(:system)
        cli.ensure_chef_cache_path
      end
    end
  end
end

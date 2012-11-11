require "spec_helper"

describe Soloist::CLI do
  let(:cli) { Soloist::CLI.new }
  let(:base_path) { Dir.mktmpdir }
  let(:soloistrc_path) { File.expand_path("soloistrc", base_path) }

  before { FileUtils.mkdir_p(base_path) }

  describe "#chef" do
    context "when the soloistrc file does not exist" do
      it "raises an error" do
        Dir.chdir(base_path) do
          expect { cli.chef }.to raise_error(Soloist::NotFound)
        end
      end
    end

    context "when the soloistrc file exists" do
      before do
        File.open(soloistrc_path, "w") do |file|
          file.write(YAML.dump("recipes" => ["stinky::feet"]))
        end
      end

      it "installs the proper recipes" do
        cli.stub(:exec)
        Dir.chdir(base_path) do
          cli.chef
        end
        cli.config.royal_crown.recipes.should =~ ["stinky::feet"]
      end

      context "when the Cheffile does not exist" do
        it "runs chef" do
          cli.should_receive(:exec)
          Dir.chdir(base_path) do
            cli.chef
          end
        end

        it "does not run librarian" do
          cli.stub(:exec)
          Librarian::Chef::Cli.should_not_receive(:with_environment)

          Dir.chdir(base_path) do
            cli.chef
          end
        end
      end

      context "when the Cheffile exists" do
        let(:cli_instance) { double(:cli_instance) }
        before do
          FileUtils.touch(File.expand_path("Cheffile", base_path))
          cli.stub(:exec)
        end

        it "runs librarian" do
          Librarian::Chef::Cli.should_receive(:with_environment).and_yield
          Librarian::Chef::Cli.should_receive(:new).and_return(cli_instance)
          cli_instance.should_receive(:install)

          Dir.chdir(base_path) do
            cli.chef
          end
        end

        it "runs chef" do
          cli.should_receive(:exec)
          Dir.chdir(base_path) do
            cli.chef
          end
        end
      end
    end
  end

  describe "#install" do
    context "when the soloistrc does not exist" do
      it "raises an error" do
        expect do
          cli.install("pineapple::wut")
        end.to raise_error(Soloist::NotFound)
      end
    end

    context "when the soloistrc file exists" do
      before do
        File.open(soloistrc_path, "w") do |file|
          file.write(YAML.dump("recipes" => ["pineapple::wutcake"]))
        end
      end

      it "sets a recipe to run" do
        Dir.chdir(base_path) do
          cli.should_receive(:chef)
          cli.install("angst::teenage", "ennui::default")
          cli.config.royal_crown.recipes.should =~ ["angst::teenage", "ennui::default"]
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

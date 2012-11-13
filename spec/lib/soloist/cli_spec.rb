require "spec_helper"

describe Soloist::CLI do
  let(:cli) { Soloist::CLI.new }
  let(:base_path) { Dir.mktmpdir }
  let(:soloistrc_path) { File.expand_path("soloistrc", base_path) }

  before { FileUtils.mkdir_p(base_path) }

  describe "#chef" do
    context "when the soloistrc file does not exist" do
      it "raises an error" do
        expect do
          begin
            Dir.chdir(base_path) { cli.chef }
          rescue Soloist::NotFound => e
            e.message.should == "Could not find soloistrc or .soloistrc"
            raise
          end
        end.to raise_error(Soloist::NotFound)
      end
    end

    context "when the soloistrc file exists" do
      before do
        File.open(soloistrc_path, "w") do |file|
          file.write(YAML.dump("recipes" => ["stinky::feet"]))
        end
      end

      it "runs the proper recipes" do
        cli.stub(:exec)
        Dir.chdir(base_path) { cli.chef }
        cli.config.royal_crown.recipes.should =~ ["stinky::feet"]
      end

      context "when a soloistrc_local file exists" do
        let(:soloistrc_local_path) { File.expand_path("soloistrc_local", base_path) }

        before do
          File.open(soloistrc_local_path, "w") do |file|
            file.write(YAML.dump("recipes" => ["stinky::socks"]))
          end
        end

        it "installs the proper recipes" do
          cli.stub(:exec)
          Dir.chdir(base_path) { cli.chef }
          cli.config.royal_crown.recipes.should =~ ["stinky::feet", "stinky::socks"]
        end
      end

      context "when the Cheffile does not exist" do
        it "runs chef" do
          cli.should_receive(:exec)
          Dir.chdir(base_path) { cli.chef }
        end

        it "does not run librarian" do
          cli.stub(:exec)
          Librarian::Chef::Cli.should_not_receive(:with_environment)
          Dir.chdir(base_path) { cli.chef }
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
          Dir.chdir(base_path) { cli.chef }
        end

        it "runs chef" do
          cli.should_receive(:exec)
          Dir.chdir(base_path) { cli.chef }
        end
      end
    end
  end

  describe "#DO_IT_LIVE" do
    context "when the soloistrc does not exist" do
      it "raises an error" do
        expect do
          Dir.chdir(base_path) { cli.DO_IT_LIVE("pineapple::wut") }
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
          cli.DO_IT_LIVE("angst::teenage", "ennui::default")
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

  describe "#chef_solo" do
    before do
      ENV["AUTREYISM"] = "pathological-yodeling"
      FileUtils.touch(File.expand_path("soloistrc", base_path))
    end

    it "receives the outside environment" do
      cli.stub(:chef_solo).and_return('echo $AUTREYISM')
      cli.should_receive(:exec) do |chef_solo|
        `#{chef_solo}`.chomp.should == "pathological-yodeling"
      end
      Dir.chdir(base_path) { cli.chef }
    end
  end
end

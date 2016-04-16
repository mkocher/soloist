require "spec_helper"

RSpec.describe Soloist::CLI do
  let(:cli) { Soloist::CLI.new }
  let(:base_path) { RSpec.configuration.tempdir }
  let(:soloistrc_path) { File.expand_path("soloistrc", base_path) }

  before do
    FileUtils.mkdir_p(base_path)
    allow_any_instance_of(Soloist::Config).to receive(:exec)
  end

  describe "#chef" do
    it "receives the outside environment" do
      FileUtils.touch(soloistrc_path)
      Dir.chdir(base_path) do
        ENV["AUTREYISM"] = "pathological-yodeling"
        expect(cli.soloist_config).to receive(:exec) do |chef_solo|
          expect(`#{chef_solo}`.chomp).to eq("pathological-yodeling")
        end
        allow(cli.soloist_config).to receive(:chef_solo).and_return('echo $AUTREYISM')
        cli.chef
      end
    end

    context "when the soloistrc file does not exist" do
      it "raises an error" do
        expect do
          begin
            Dir.chdir(base_path) { cli.chef }
          rescue Soloist::NotFound => e
            expect(e.message).to eq("Could not find soloistrc or .soloistrc")
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
        cli.soloist_config = nil
        Dir.chdir(base_path) { allow(cli.soloist_config).to receive(:exec) }
      end

      it "runs the proper recipes" do
        cli.chef
        expect(cli.soloist_config.royal_crown.recipes).to match_array(["stinky::feet"])
      end

      context "when a soloistrc_local file exists" do
        let(:soloistrc_local_path) { File.expand_path("soloistrc_local", base_path) }

        before do
          File.open(soloistrc_local_path, "w") do |file|
            file.write(YAML.dump("recipes" => ["stinky::socks"]))
          end
          cli.soloist_config = nil
          Dir.chdir(base_path) { allow(cli.soloist_config).to receive(:exec) }
        end

        it "installs the proper recipes" do
          cli.chef
          expect(cli.soloist_config.royal_crown.recipes).to match_array(["stinky::feet", "stinky::socks"])
        end
      end

      context "when the Cheffile does not exist" do
        it "runs chef" do
          expect(cli.soloist_config).to receive(:exec)
          cli.chef
        end

        it "does not run librarian" do
          expect(Librarian::Chef::Cli).to_not receive(:with_environment)
          cli.chef
        end
      end

      context "when the Cheffile exists" do
        let(:cli_instance) { double(:cli_instance) }

        before { FileUtils.touch(File.expand_path("Cheffile", base_path)) }

        it "runs librarian" do
          expect(Librarian::Chef::Cli).to receive(:with_environment).and_yield
          expect(Librarian::Chef::Cli).to receive(:new).and_return(cli_instance)
          expect(cli_instance).to receive(:install)
          cli.chef
        end

        context "when the user is not root" do
          it "creates the cache path using sudo" do
            expect(cli.soloist_config).to receive(:exec) do |command|
              expect(command).to match(/^sudo -E/)
            end
            cli.chef
          end
        end

        context "when the user is root" do
          before { allow(Process).to receive(:uid).and_return(0) }

          it "creates the cache path" do
            expect(cli.soloist_config).to receive(:exec) do |command|
              expect(command).to_not match(/^sudo -E/)
            end
            cli.chef
          end
        end
      end
    end
  end

  describe "#run_recipe" do
    context "when the soloistrc does not exist" do
      it "raises an error" do
        expect do
          Dir.chdir(base_path) { cli.run_recipe("pineapple::wut") }
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
          expect(cli).to receive(:chef)
          cli.run_recipe("angst::teenage", "ennui::default")
          expect(cli.soloist_config.royal_crown.recipes).to match_array(["angst::teenage", "ennui::default"])
        end
      end
    end
  end

  describe "#config" do
    let(:royal_crown) { Soloist::RoyalCrown.new(:node_attributes => {"a" => "b"}) }
    let(:config) { Soloist::Config.new(royal_crown) }

    before { allow(cli).to receive(:soloist_config).and_return(config) }

    it "prints the hash render of the RoyalCrown" do
      expect(Kernel).to receive(:ap).with({"recipes"=>[], "a" => "b"})
      cli.config
    end
  end
end

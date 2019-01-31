require "librarian/chef/cli"
require "soloist/config"
require "soloist/spotlight"
require "thor"

module Soloist
  class CLI < Thor
    attr_writer :soloist_config
    default_task :chef

    desc "chef", "Run chef-solo"
    def chef
      install_cookbooks if cheffile_exists?
      soloist_config.run_chef
    end

    desc "run_recipe [cookbook::recipe, ...]", "Run individual recipes"
    def run_recipe(*recipes)
      soloist_config.royal_crown.recipes = recipes
      chef
    end

    desc "config", "Dumps configuration data for Soloist"
    def config
      Kernel.ap(soloist_config.as_node_json)
    end

    no_tasks do
      def install_cookbooks
        Dir.chdir(File.dirname(rc_path)) do
          Librarian::Chef::Cli.with_environment do
            Librarian::Chef::Cli.new.install
          end
        end
      end

      def soloist_config
        @soloist_config ||= Soloist::Config.from_file(rc_path).tap do |config|
          config.merge!(rc_local) if rc_local_path
        end
      end
    end

    private
    def rc_local
      Soloist::Config.from_file(rc_local_path)
    end

    def cheffile_exists?
      File.exists?(File.expand_path("../Cheffile", rc_path))
    end

    def rc_path
      @rc_path ||= Soloist::Spotlight.find!("soloistrc", ".soloistrc")
    end

    def rc_local_path
      @rc_local_path ||= Soloist::Spotlight.find("soloistrc_local", ".soloistrc_local")
    end
  end
end

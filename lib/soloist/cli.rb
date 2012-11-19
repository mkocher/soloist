require "librarian/chef/cli"
require "soloist/known_hosts"
require "soloist/spotlight"
require "soloist/config"
require "soloist/remote"
require "thor"
require "awesome_print"

module Soloist
  class CLI < Thor
    default_task :chef

    desc "chef", "Run chef-solo"
    def chef
      ensure_chef_cache_path
      install_cookbooks if cheffile_exists?
      run_chef
    end

    desc "run_recipe", "Run individual recipes"
    def run_recipe(*recipes)
      soloist_config.royal_crown.recipes = recipes
      chef
    end

    desc "config", "Dumps configuration data for Soloist"
    def config
      Kernel.ap(soloist_config.as_node_json)
    end

    no_tasks do
      def run_chef
        exec(conditional_sudo("bash -c '#{soloist_config.chef_solo}'"))
      end

      def ensure_chef_cache_path
        unless File.directory?("/var/chef/cache")
          system(conditional_sudo("mkdir -p /var/chef/cache"))
        end
      end

      def install_cookbooks
        Dir.chdir(File.dirname(rc_path)) do
          Librarian::Chef::Cli.with_environment do
            Librarian::Chef::Cli.new.install
          end
        end
      end

      def soloist_config
        @soloist_config ||= begin
          Soloist::Config.from_file(rc_path, log_level).tap do |config|
            Soloist::Config.from_file(rc_local_path, log_level).tap do |local|
              config.merge!(local)
            end if rc_local_path
          end
        end
      end
    end

    private
    def conditional_sudo(command)
      root? ? command : "sudo -E #{command}"
    end

    def root?
      Process.uid == 0
    end

    def log_level
      ENV["LOG_LEVEL"] || "info"
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

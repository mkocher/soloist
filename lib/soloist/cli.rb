require "librarian/chef/cli"
require "soloist/known_hosts"
require "soloist/spotlight"
require "soloist/config"
require "soloist/remote"
require "tempfile"
require "thor"

module Soloist
  class CLI < Thor
    default_task :chef

    desc "chef", "Runs chef-solo"
    def chef
      ensure_chef_cache_path
      write_solo_rb
      write_node_json
      install_cookbooks if cheffile_exists?
      exec(conditional_sudo("bash -c '#{chef_solo}'"))
    end

    desc "run_recipe", "Runs an individual recipe with chef-solo"
    def DO_IT_LIVE(*recipes)
      config.royal_crown.recipes = recipes
      chef
    end

    no_tasks do
      def write_solo_rb
        content = config.as_solo_rb
        content.each{ |line| puts line } if log_level == "debug"
        File.open(solo_rb.path, "w") { |f| f.write(content) }
      end

      def write_node_json
        content = config.as_json
        puts JSON.pretty_generate(content) if log_level == "debug"
        File.open(node_json.path, "w") { |f| f.write(JSON.dump(content)) }
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

      def config
        @config ||= begin
          Soloist::Config.from_file(rc_path).tap do |config|
            Soloist::Config.from_file(rc_local_path).tap do |local|
              config.merge!(local)
            end if rc_local_path
          end
        end
      end

      def chef_solo
        "chef-solo -j '#{node_json.path}' -c '#{solo_rb.path}' -l '#{log_level}'"
      end
    end

    private
    def conditional_sudo(command)
      root? ? command : "sudo -E #{command}"
    end

    def root?
      Process.uid == 0
    end

    def cheffile_exists?
      File.exists?(File.expand_path("../Cheffile", rc_path))
    end

    def log_level
      ENV["LOG_LEVEL"] || "info"
    end

    def solo_rb
      @solo_rb ||= Tempfile.new(["solo", ".rb"])
    end

    def node_json
      @node_json ||= Tempfile.new(["node", ".json"])
    end

    def rc_path
      @rc_path ||= Soloist::Spotlight.find!("soloistrc", ".soloistrc")
    end

    def rc_local_path
      @rc_local_path ||= Soloist::Spotlight.find("soloistrc_local", ".soloistrc_local")
    end
  end
end

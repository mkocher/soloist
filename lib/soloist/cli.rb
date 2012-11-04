require "librarian/chef/cli"
require "soloist/spotlight"
require "soloist/config"
require "thor"

module Soloist
  class NotFound < RuntimeError; end

  class CLI < Thor
    desc "run_chef", "Runs chef-solo like a baws"
    def run_chef
      ensure_chef_cache_path
      raise Soloist::NotFound.new("Could not find soloistrc") unless rc_path
      File.open(solo_rb_path, "w+") { |f| f.write(config.as_solo_rb) }
      File.open(node_json_path, "w+") { |f| f.write(config.as_json) }
      install_cookbooks
      exec("sudo bash -c '#{environment} #{chef_solo_command}'")
    end

    no_tasks do
      def ensure_chef_cache_path
        unless File.directory?("/var/chef/cache")
          system("sudo mkdir -p /var/chef/cache")
        end
      end

      def install_cookbooks
        Dir.chdir(File.dirname(rc_path)) do
          Librarian::Chef::Cli.with_environment do
            Librarian::Chef::Cli.new.install
          end
        end
      end
    end

    private
    def chef_solo_command
      "chef-solo -j #{node_json_path} -c #{solo_rb_path} -l #{log_level}"
    end

    def environment
      config.as_env.map{ |k, v| "#{k}=#{v}" }.join(" ")
    end

    def log_level
      ENV["LOG_LEVEL"] || "info"
    end

    def solo_rb_path
      @solo_rb_path ||= Tempfile.new("solo.rb")
    end

    def node_json_path
      @node_json_path ||= Tempfile.new("node.json")
    end

    def config
      @config ||= Soloist::Config.from_file(Dir.pwd, rc_path)
    end

    def rc_path
      @rc_path ||= ["soloistrc", ".soloistrc"].detect do |file_name|
        spotlight.search_for(file_name)
      end
    end

    def spotlight
      @spotlight ||= Soloist::Spotlight.new(Dir.pwd)
    end
  end
end

require "librarian/chef/cli"
require "soloist/spotlight"
require "soloist/config"
require "tempfile"
require "thor"

module Soloist
  class NotFound < RuntimeError; end

  class CLI < Thor
    default_task :run_chef

    desc "run_chef", "Runs chef-solo like a baws"
    def run_chef
      ensure_chef_cache_path
      raise Soloist::NotFound.new("Could not find soloistrc") unless rc_path
      write_solo_rb
      write_node_json
      install_cookbooks
      exec("sudo bash -c '#{environment} #{chef_solo}'")
    end

    no_tasks do
      def write_solo_rb
        content = config.as_solo_rb
        content.each{ |line| puts line } if log_level == "debug"
        File.open(solo_rb.path, "w") { |f| f.write(content.join("\n")) }
      end

      def write_node_json
        content = config.as_json
        puts JSON.pretty_generate(content) if log_level == "debug"
        File.open(node_json.path, "w") { |f| f.write(JSON.dump(content)) }
      end

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
    def chef_solo
      "chef-solo -j '#{node_json.path}' -c '#{solo_rb.path}' -l '#{log_level}'"
    end

    def environment
      config.as_env.map{ |k, v| "#{k}=#{v}" }.join(" ")
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

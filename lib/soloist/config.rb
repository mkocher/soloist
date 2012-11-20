require "soloist/royal_crown"
require "tempfile"

module Soloist
  class Config
    attr_writer :solo_rb_path, :node_json_path
    attr_reader :royal_crown

    def self.from_file(royal_crown_path)
      rc = Soloist::RoyalCrown.from_file(royal_crown_path)
      new(rc)
    end

    def initialize(royal_crown)
      @royal_crown = royal_crown
    end

    def run_chef
      exec(conditional_sudo("bash -c '#{chef_solo}'"))
    end

    def ensure_chef_cache_path
      unless File.directory?("/var/chef/cache")
        system(conditional_sudo("mkdir -p /var/chef/cache"))
      end
    end

    def chef_solo
      "chef-solo -j '#{node_json_path}' -c '#{solo_rb_path}' -l '#{log_level}'"
    end

    def as_solo_rb
      "cookbook_path #{cookbook_paths.inspect}"
    end

    def as_node_json
      compiled.node_attributes.to_hash.merge({ "recipes" => compiled.recipes })
    end

    def solo_rb_path
      @solo_rb_path ||= Tempfile.new(["solo", ".rb"]).tap do |file|
        puts content if debug?
        file.write(as_solo_rb)
      end
    end

    def node_json_path
      @node_json_path ||= Tempfile.new(["node", ".json"]).tap do |file|
        puts JSON.pretty_generate(content) if debug?
        file.write(JSON.dump(as_node_json))
      end
    end

    def merge!(other)
      royal_crown.recipes += other.royal_crown.recipes
      royal_crown.cookbook_paths += other.royal_crown.cookbook_paths
      royal_crown.node_attributes.merge!(other.royal_crown.node_attributes)
      royal_crown.env_variable_switches.merge!(other.royal_crown.env_variable_switches)
    end

    private
    def log_level
      ENV["LOG_LEVEL"] || "info"
    end

    def debug?
      log_level == "debug"
    end

    def conditional_sudo(command)
      root? ? command : "sudo -E #{command}"
    end

    def root?
      Process.uid == 0
    end

    def compiled
      @compiled ||= royal_crown.dup.tap do |rc|
        while rc["env_variable_switches"]
          rc.delete("env_variable_switches").each do |variable, switch|
            switch.each do |value, inner|
              rc.merge!(inner) if ENV[variable] == value
            end
          end
        end
      end
    end

    def cookbook_paths
      ([royal_crown_cookbooks_directory] + compiled.cookbook_paths).map do |path|
        File.expand_path(path, royal_crown_path)
      end.uniq.select do |path|
        File.directory?(path)
      end
    end

    def royal_crown_cookbooks_directory
      File.expand_path("cookbooks", royal_crown_path)
    end

    def royal_crown_path
      File.dirname(royal_crown.path)
    end
  end
end

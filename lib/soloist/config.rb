require "soloist/royal_crown"
require "tempfile"

module Soloist
  class Config
    attr_writer :solo_rb_path, :node_json_path
    attr_reader :royal_crown, :log_level

    def self.from_file(royal_crown_path, log_level = "info")
      rc = Soloist::RoyalCrown.from_file(royal_crown_path)
      new(rc, log_level)
    end

    def initialize(royal_crown, log_level = "info")
      @royal_crown = royal_crown
      @log_level = log_level
    end

    def chef_solo
      "chef-solo -j '#{node_json.path}' -c '#{solo_rb.path}' -l '#{log_level}'"
    end

    def as_solo_rb
      "cookbook_path #{expanded_cookbook_directories.inspect}"
    end

    def as_node_json
      compiled.node_attributes.to_hash.merge({ "recipes" => compiled.recipes })
    end

    def solo_rb_path
      @solo_rb_path ||= Tempfile.new(["solo", ".rb"])
    end

    def node_json_path
      @node_json_path ||= Tempfile.new(["node", ".json"])
    end

    def solo_rb
      @solo_rb ||= solo_rb_path.tap do |file|
        puts content if debug?
        file.write(as_solo_rb)
      end
    end

    def node_json
      @node_json ||= node_json_path.tap do |file|
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

    def debug?
      log_level == "debug"
    end

    def expanded_cookbook_directories
      expanded_cookbook_paths.select { |path| File.directory?(path) }
    end

    def expanded_cookbook_paths
      cookbook_paths.map { |path| File.expand_path(path, royal_crown_path) }.uniq
    end

    def cookbook_paths
      [royal_crown_cookbooks_directory] + compiled.cookbook_paths
    end

    def royal_crown_cookbooks_directory
      File.expand_path("cookbooks", royal_crown_path)
    end

    def royal_crown_path
      File.dirname(royal_crown.path)
    end
  end
end

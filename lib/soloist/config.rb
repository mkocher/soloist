require "soloist/royal_crown"

module Soloist
  class Config
    attr_reader :royal_crown

    def self.from_file(royal_crown_path)
      rc = Soloist::RoyalCrown.from_file(royal_crown_path)
      new(rc)
    end

    def initialize(royal_crown)
      @royal_crown = royal_crown
    end

    def as_solo_rb
      "cookbook_path #{expanded_cookbook_directories.inspect}"
    end

    def as_json
      {
        "recipes" => compiled_rc.recipes
      }
    end

    def compiled_rc
      @compiled_rc ||= royal_crown.dup.tap do |rc|
        while rc["env_variable_switches"]
          rc.delete("env_variable_switches").each do |variable, switch|
            switch.each do |value, inner|
              rc.merge!(inner) if ENV[variable] == value
            end
          end
        end
      end
    end

    def merge!(other)
      royal_crown.recipes += other.royal_crown.recipes
      royal_crown.cookbook_paths += other.royal_crown.cookbook_paths
      royal_crown.node_attributes.merge!(other.royal_crown.node_attributes)
      royal_crown.env_variable_switches.merge!(other.royal_crown.env_variable_switches)
    end

    private
    def expanded_cookbook_directories
      expanded_cookbook_paths.select { |path| File.directory?(path) }
    end

    def expanded_cookbook_paths
      cookbook_paths.map { |path| File.expand_path(path, royal_crown_path) }.uniq
    end

    def cookbook_paths
      [royal_crown_cookbooks_directory] + compiled_rc.cookbook_paths
    end

    def royal_crown_cookbooks_directory
      File.expand_path("cookbooks", royal_crown_path)
    end

    def royal_crown_path
      File.dirname(royal_crown.path)
    end
  end
end

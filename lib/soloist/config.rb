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
      paths = cookbook_paths.uniq.map do |cookbook_path|
        File.expand_path(cookbook_path, bash_path)
      end
      "cookbook_path #{paths.inspect}"
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

    private
    def bash_path
      File.dirname(royal_crown.path)
    end

    def cookbook_paths
      ["cookbooks"] + compiled_rc.cookbook_paths
    end
  end
end

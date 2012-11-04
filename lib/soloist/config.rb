require "soloist/royal_crown"

module Soloist
  class Config
    attr_reader :working_path, :royal_crown

    PROPAGATED_ENV = %w{PATH BUNDLE_PATH GEM_HOME GEM_PATH RAILS_ENV RACK_ENV}

    def self.from_file(working_path, royal_crown_path)
      rc = Soloist::RoyalCrown.from_file(royal_crown_path)
      new(working_path, rc)
    end

    def initialize(working_path, royal_crown)
      @working_path = working_path
      @royal_crown = royal_crown
    end

    def as_solo_rb
      cookbook_paths.uniq.map do |cookbook_path|
        %{cookbook_path "#{File.expand_path(cookbook_path)}"}
      end
    end

    def as_json
      {
        "recipes" => compiled_rc.recipes
      }
    end

    def as_env
      environment_variables.reduce({}) do |result_env, variable|
        result_env.tap do |env|
          env[variable] = ENV[variable] if ENV[variable]
        end
      end
    end

    def compiled_rc
      @compiled_rc ||= royal_crown.dup.tap do |rc|
        rc.delete("env_variable_switches").each do |variable, switch|
          switch.each do |value, mergeable|
            rc.merge!(mergeable) if ENV[variable] == value
          end
        end
      end
    end

    private
    def environment_variables
      PROPAGATED_ENV + royal_crown.env_variable_switches.keys.map(&:to_s)
    end

    def cookbook_paths
      [File.expand_path("cookbooks", working_path)] + compiled_rc.cookbook_paths
    end
  end
end

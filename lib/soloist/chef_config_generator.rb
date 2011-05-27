require 'yaml'

module Soloist
  class Soloist::ChefConfigGenerator
    def initialize(yaml_string, relative_path_to_soloistrc)
      @hash = YAML.load(yaml_string)
      @relative_path_to_soloistrc = relative_path_to_soloistrc
      merge_env_variable_switches
    end
  
    def merge_config(sub_hash)
      if sub_hash["recipes"]
        @hash["recipes"] ||= []
        @hash["recipes"] = (@hash["recipes"] + sub_hash["recipes"]).uniq
      end
      if sub_hash["cookbook_paths"]
        @hash["cookbook_paths"] ||= []
        @hash["cookbook_paths"] = (@hash["cookbook_paths"] + sub_hash["cookbook_paths"]).uniq
      end
    end
  
    def merge_env_variable_switches
      return unless @hash["env_variable_switches"]
      @hash["env_variable_switches"].keys.each do |variable|
        ENV[variable] && ENV[variable].split(',').each do |env_variable_value|
          sub_hash = @hash["env_variable_switches"][variable] && @hash["env_variable_switches"][variable][env_variable_value]
          merge_config(sub_hash) if sub_hash
        end
      end
    end
  
    def cookbook_paths
      (@hash["cookbook_paths"] || @hash["Cookbook_Paths"]).map do |v|
        (v =~ /\//) == 0 ? v : "#{FileUtils.pwd}/#{@relative_path_to_soloistrc}/#{v}"
      end
    end
  
    def solo_rb
      "cookbook_path #{cookbook_paths.inspect}"
    end
  
    def json_hash
      recipes = @hash["Recipes"] || @hash["recipes"]
      {
        "recipes" => recipes
      }
    end
  
    def json_file
      json_hash.to_json
    end
  
    def preserved_environment_variables
      passed = %w{PATH BUNDLE_PATH GEM_HOME GEM_PATH RAILS_ENV RACK_ENV}
      passed += @hash["env_variable_switches"].keys if @hash["env_variable_switches"]
      passed
    end
  
    def preserved_environment_variables_string
      variable_array = []
      preserved_environment_variables.map do |env_variable|
        "#{env_variable}=#{ENV[env_variable]}" unless ENV[env_variable].nil?
      end.compact.join(" ")
    end
  end
end
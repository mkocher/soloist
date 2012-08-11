require 'yaml'

module Soloist
  class Soloist::ChefConfigGenerator
    include Soloist::Util
    
    def initialize(config, relative_path_to_soloistrc)
      @recipes = []
      @cookbook_paths = []
      @cookbook_gems = []
      @preserved_environment_variables = %w{PATH BUNDLE_PATH GEM_HOME GEM_PATH RAILS_ENV RACK_ENV}
      @node_attributes = config['node_attributes'] || {}
      merge_config(config, relative_path_to_soloistrc)
    end
    
    attr_reader :preserved_environment_variables, :cookbook_paths, :cookbook_gems
    attr_accessor :recipes
    
    def support_old_format(hash)
      hash['recipes'] ||= hash.delete('Recipes')
      hash['cookbook_paths'] ||= hash.delete('Cookbook_Paths')
      hash
    end
    
    def append_path(paths, relative_path_to_soloistrc)
      paths.map do |path|
        path.slice(0,1) == '/' ? path : "#{FileUtils.pwd}/#{relative_path_to_soloistrc}/#{path}"
      end
    end
  
    def merge_config(sub_hash, relative_path_to_soloistrc)
      sub_hash = support_old_format(sub_hash)
      if sub_hash["recipes"]
        @recipes = (@recipes + sub_hash["recipes"]).uniq
      end
      if sub_hash["cookbook_paths"]
        @cookbook_paths = (@cookbook_paths + append_path(sub_hash["cookbook_paths"], relative_path_to_soloistrc)).uniq
      end
      if sub_hash["cookbook_gems"]
        (@cookbook_gems += sub_hash["cookbook_gems"]).uniq!
      end
      if sub_hash["env_variable_switches"]
        merge_env_variable_switches(sub_hash["env_variable_switches"], relative_path_to_soloistrc)
      end
    end
  
    def merge_env_variable_switches(hash_to_merge, relative_path_to_soloistrc)
      hash_to_merge.keys.each do |variable|
        @preserved_environment_variables << variable
        ENV[variable] && ENV[variable].split(',').each do |env_variable_value|
          sub_hash = hash_to_merge[variable] && hash_to_merge[variable][env_variable_value]
          merge_config(sub_hash, relative_path_to_soloistrc) if sub_hash
        end
      end
    end
  
    def solo_rb
      linker = CookbookGemLinker.new(cookbook_gems)
      linker.link_gem_cookbooks
      "cookbook_path #{(cookbook_paths+[linker.cookbook_gem_temp_dir]).inspect}"
    end

    def json_hash
      {
        "recipes" => @recipes
      }.merge(@node_attributes)
    end
  
    def json_file
      json_hash.to_json
    end
  
    def preserved_environment_variables_string
      variable_array = []
      preserved_environment_variables.map do |env_variable|
        "#{env_variable}=#{ENV[env_variable]}" unless ENV[env_variable].nil?
      end.compact.join(" ")
    end
  end
end
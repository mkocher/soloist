module Soloist
  class RoyalCrown
    attr_accessor :path, :node_attributes, :cookbook_paths, :recipes, :env_variable_switches

    def self.from_file(file_path)
      new(read_config(file_path).merge("path" => file_path).reject { |_, value| value.nil? })
    end

    def self.read_config(yaml_file)
      content = File.read(yaml_file)
      parsed_content = ERB.new(content).result
      YAML.load(parsed_content) || {}
    end

    def initialize(attributes = {})
      @path = attributes.fetch(:path, attributes.fetch('path', nil))
      @recipes = attributes.fetch(:recipes, attributes.fetch('recipes', []))
      @cookbook_paths = attributes.fetch(:cookbook_paths, attributes.fetch('cookbook_paths', []))
      @node_attributes = attributes.fetch(:node_attributes, attributes.fetch('node_attributes', {}))
      @env_variable_switches = attributes.fetch(:env_variable_switches, attributes.fetch('env_variable_switches', {}))
    end

    def to_yaml
      {
        'recipes' => recipes.empty? ? nil : recipes,
        'cookbook_paths' => cookbook_paths.empty? ? nil : cookbook_paths,
        'node_attributes' => node_attributes.empty? ? nil : node_attributes,
        'env_variable_switches' => env_variable_switches.empty? ? nil : env_variable_switches
      }
    end

    def merge!(other_royal_crown)
      @recipes = recipes.concat(other_royal_crown.recipes).uniq
      @cookbook_paths = cookbook_paths.concat(other_royal_crown.cookbook_paths).uniq
      @node_attributes = deep_merge(node_attributes, other_royal_crown.node_attributes)
      @env_variable_switches = deep_merge(env_variable_switches, other_royal_crown.env_variable_switches)
    end

    def save
      return self unless path
      File.open(path, "w+") { |file| file.write(YAML.dump(to_yaml)) }
      self
    end

    def reload
      self.class.from_file(path)
    end

    private
    def deep_merge(first_hash, second_hash)
      deep_merger = Proc.new do |key, first, second|
        if first.is_a?(Hash) && second.is_a?(Hash)
          first.merge(second, &deep_merger)
        elsif first.is_a?(Array) && second.is_a?(Array)
          first.concat(second)
        elsif v2.nil?
          v1
        else
          v2
        end
      end
      first_hash.merge(second_hash, &deep_merger)
    end
  end
end

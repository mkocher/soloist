require "hashie"

module Soloist
  class RoyalCrown < Hashie::Trash
    property :path
    property :recipes, :default => []
    property :cookbook_paths, :default => []
    property :node_attributes, :default => Hashie::Mash.new,
             :transform_with => lambda { |v| Hashie::Mash.new(v) }
    property :env_variable_switches, :default => Hashie::Mash.new,
             :transform_with => lambda { |v| Hashie::Mash.new(v) }

    def node_attributes=(hash)
      self["node_attributes"] = Hashie::Mash.new(hash)
    end

    def env_variable_switches=(hash)
      self["env_variable_switches"] = Hashie::Mash.new(hash)
    end

    def to_yaml
      to_hash.tap do |hash|
        hash.delete("path")
        self.class.nilable_properties.each { |k| hash[k] = nil if hash[k].empty? }
      end
    end

    def save
      return self unless path
      File.open(path, "w+") { |file| file.write(YAML.dump(to_yaml)) }
      self
    end

    def reload
      self.class.from_file(path)
    end

    def self.from_file(file_path)
      new(read_config(file_path).merge("path" => file_path))
    end

    def self.read_config(yaml_file)
      content = File.read(yaml_file)
      YAML.load(content).tap do |hash|
        nilable_properties.each do |key|
          hash.delete(key) if hash[key].nil?
        end if hash
      end || {}
    end

    private
    def self.nilable_properties
      (properties - [:path]).map(&:to_s)
    end
  end
end

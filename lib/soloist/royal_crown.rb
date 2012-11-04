require "hashie"

module Soloist
  class RoyalCrown < Hashie::Dash
    property :path
    property :cookbook_paths, :default => []
    property :recipes, :default => []
    property :node_attributes, :default => {}
    property :env_variable_switches, :default => {}

    EMPTY_INSTEAD_OF_NIL = ["cookbook_paths", "recipes", "node_attributes", "env_variable_switches"]

    def self.from_file(file_path)
      yaml = YAML.load_file(file_path).tap do |hash|
        EMPTY_INSTEAD_OF_NIL.each { |key| hash.delete(key) if hash[key].nil? }
      end

      new(yaml.merge("path" => file_path))
    end

    def to_hash
      super.tap do |hash|
        hash.delete("path")
        EMPTY_INSTEAD_OF_NIL.each { |key| hash[key] = nil if hash[key].empty? }
      end
    end

    def save
      File.open(path, "w") { |f| f.write(YAML.dump(to_hash)) }
    end
  end
end

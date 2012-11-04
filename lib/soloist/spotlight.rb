module Soloist
  class Spotlight
    attr_reader :path_parts

    def initialize(path)
      @path_parts = path.split(File::SEPARATOR)
    end

    def search_for(name)
      parents.map{ |p| File.expand_path(name, p) }.detect{ |f| File.exists?(f) }
    end

    def parents
      @parents ||= (0..path_parts.length).map do |last|
        File.join(path_parts[0..last])
      end
    end
  end
end

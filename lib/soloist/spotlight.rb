require 'pathname'

module Soloist
  class Spotlight
    attr_reader :pathname

    def initialize(path)
      @pathname = Pathname.new(path)
    end

    def search_for(name)
      pathname.ascend do |path|
        file_path = File.expand_path(name, path)
        break file_path if File.exists?(file_path)
      end
    end
  end
end

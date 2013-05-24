require 'pathname'

module Soloist
  class NotFound < RuntimeError; end

  class Spotlight
    attr_reader :pathname

    def self.find(*file_names)
      new(Dir.pwd).find(*file_names)
    end

    def self.find!(*file_names)
      options = file_names.last.is_a?(Hash) ? file_names.pop : {}
      new(Dir.pwd, options).find!(*file_names)
    end

    def initialize(path, options={})
      @pathname = Pathname.new(path)
      @options  = options
    end

    def find(*file_names)
      if @options[:custom_path]
        path      = Pathname.new(@options[:custom_path])
        file_name = file_names.detect { |fn| path.join(fn).file? }

        return path.join(file_name) if file_name
      end

      pathname.ascend do |path|
        file_name = file_names.detect { |fn| path.join(fn).file? }
        break path.join(file_name) if file_name
      end
    end

    def find!(*file_names)
      file_path = find(*file_names)
      unless file_path
        file_names = if file_names.length > 2
          file_names[0...-1].join(", ") + " or " + file_names.last
        else
          file_names.join(" or ")
        end
        raise Soloist::NotFound.new("Could not find #{file_names}")
      end
      file_path
    end
  end
end

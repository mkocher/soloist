require "librarian/chef/cli"

module Soloist
  class Config
    attr_reader :working_path, :royal_crown

    def initialize(working_path, royal_crown)
      @working_path = working_path
      @royal_crown = royal_crown
    end

    def solo_rb
      cookbook_paths.map do |cookbook_path|
        %{cookbook_path "#{File.expand_path(cookbook_path)}"}
      end.join("\n")
    end

    def install_cookbooks
      Librarian::Chef::Cli.with_environment { |*| Librarian::Chef::Cli.new.install }
    end

    private
    def cookbook_paths
      [File.expand_path("cookbooks", working_path)] + royal_crown.cookbook_paths
    end
  end
end

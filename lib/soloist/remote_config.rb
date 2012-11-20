require "soloist/config"
require "soloist/remote"

module Soloist
  class RemoteConfig < Config
    attr_reader :remote

    def self.from_file(royal_crown_path, remote)
      rc = Soloist::RoyalCrown.from_file(royal_crown_path)
      new(rc, remote)
    end

    def initialize(royal_crown, remote)
      @royal_crown = royal_crown
      @remote = remote
    end

    def run_chef
      remote.system!(chef_solo)
    end

    def node_json_path
      @node_json_path ||= remote.backtick("mktemp -t node.json").tap do |path|
        remote.system!("echo '#{as_node_json}' | tee #{path} > /dev/null")
      end
    end

    def solo_rb_path
      @solo_rb_path ||= remote.backtick("mktemp -t solo.rb").tap do |path|
        remote.system!("echo '#{as_solo_rb}' | tee #{path}")
      end
    end

    def ensure_chef_path
      remote.system!("mkdir -p /var/chef/cache")
    end
  end
end

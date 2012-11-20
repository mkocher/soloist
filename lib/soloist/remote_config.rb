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
      remote.system!("#{export_environment} && #{conditional_sudo(chef_solo)}")
    end

    def export_environment
      ENV.map{ |k, v| "export #{k}=#{v}" }.join(" && ")
    end

    def node_json_path
      @node_json_path ||= remote.backtick("mktemp -t node.json").tap do |path|
        tee = conditional_sudo("tee #{path}")
        remote.system!("echo '#{JSON.dump(as_node_json)}' | #{tee} > /dev/null")
      end
    end

    def solo_rb_path
      @solo_rb_path ||= remote.backtick("mktemp -t solo.rb").tap do |path|
        tee = conditional_sudo("tee #{path}")
        remote.system!("echo '#{as_solo_rb}' | #{tee} > /dev/null")
      end
    end

    def ensure_chef_path
      remote.system!(conditional_sudo("mkdir -p /var/chef/cache"))
    end

    protected
    def conditional_sudo(command)
      root? ? command : "sudo -E #{command}"
    end

    def root?
      remote.user == "root"
    end
  end
end

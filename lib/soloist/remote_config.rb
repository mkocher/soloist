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
      remote.system!(conditional_sudo(%(/bin/bash -lc "#{chef_solo}")))
    end

    def node_json_path
      @node_json_path ||= File.expand_path("node.json", chef_config_path).tap do |path|
        remote.system!(%(echo '#{JSON.dump(as_node_json)}' | #{conditional_sudo("tee #{path}")}))
      end
    end

    def solo_rb_path
      @solo_rb_path ||= File.expand_path("solo.rb", chef_config_path).tap do |path|
        remote.system!(%(echo '#{as_solo_rb}' | #{conditional_sudo("tee #{path}")}))
      end
    end

    def chef_cache_path
      @chef_cache_path ||= "/var/chef/cache".tap do |cache_path|
        remote.system!(conditional_sudo("/bin/mkdir -m 777 -p #{cache_path}"))
      end
    end

    def chef_config_path
      @chef_config_path ||= "/etc/chef".tap do |path|
        remote.system!(conditional_sudo("/bin/mkdir -m 777 -p #{path}"))
      end
    end

    def cookbook_paths
      @cookbook_paths ||= ["/var/chef/cookbooks".tap do |remote_path|
        remote.system!(conditional_sudo("/bin/mkdir -m 777 -p #{remote_path}"))
        super.each { |path| remote.upload("#{path}/", remote_path) }
      end]
    end

    protected
    def conditional_sudo(command)
      root? ? command : "/usr/bin/sudo -E #{command}"
    end

    def root?
      remote.user == "root"
    end
  end
end

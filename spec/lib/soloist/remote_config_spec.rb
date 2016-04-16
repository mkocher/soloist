require "spec_helper"

RSpec.describe Soloist::RemoteConfig do
  let(:royal_crown_path) { File.expand_path("soloistrc", RSpec.configuration.tempdir) }
  let(:royal_crown) { Soloist::RoyalCrown.new(:path => royal_crown_path) }
  let(:remote) { Soloist::Remote.new("user", "host", "key") }
  let(:remote_config) { Soloist::RemoteConfig.new(royal_crown, remote) }

  before { allow(remote).to receive_messages(:backtick => "", :system => 0) }

  def commands_for(method)
    [].tap do |commands|
      allow(remote).to receive(:system) { |c| commands << c; 0 }
      allow(remote).to receive(:backtick) { |c| commands << c; "" }
      remote_config.send(method)
    end
  end

  describe "#run_chef" do
    it "runs chef" do
      expect(commands_for(:run_chef).last).to include "chef-solo"
    end
  end

  describe "#solo_rb_path" do
    it "sets the path to /etc/chef/solo.rb" do
      expect(remote_config.solo_rb_path).to eq("/etc/chef/solo.rb")
    end

    it "sets up solo.rb remotely" do
      expect(commands_for(:solo_rb_path).last).to match(/sudo -E tee \/etc\/chef\/solo\.rb$/)
    end
  end

  describe "#node_json_path" do
    it "sets the path" do
      expect(remote_config.node_json_path).to eq("/etc/chef/node.json")
    end

    it "sets up node.json remotely" do
      expect(commands_for(:node_json_path).last).to match(/sudo -E tee \/etc\/chef\/node\.json$/)
    end
  end

  describe "#chef_config_path" do
    it "sets the path" do
      expect(remote_config.chef_config_path).to eq("/etc/chef")
    end

    it "creates the path remotely" do
      commands_for(:chef_config_path).tap do |commands|
        expect(commands.size).to eq(1)
        expect(commands.first).to match(/mkdir .*? -p \/etc\/chef$/)
      end
    end
  end

  describe "#chef_cache_path" do
    it "sets the path" do
      expect(remote_config.chef_cache_path).to eq("/var/chef/cache")
    end

    it "creates the path remotely" do
      commands_for(:chef_cache_path).tap do |commands|
        expect(commands.size).to eq(1)
        expect(commands.first).to match(/mkdir .*? -p \/var\/chef\/cache$/)
      end
    end
  end

  describe "#cookbook_paths" do
    it "sets the path" do
      expect(remote_config.cookbook_paths.size).to eq(1)
      expect(remote_config.cookbook_paths).to match_array(["/var/chef/cookbooks"])
    end

    it "creates the path remotely" do
      commands_for(:cookbook_paths).tap do |commands|
        expect(commands.size).to eq(1)
        expect(commands.first).to match(/mkdir .*? -p \/var\/chef\/cookbooks$/)
      end
    end
  end
end

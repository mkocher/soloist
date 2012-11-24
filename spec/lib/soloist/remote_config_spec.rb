require "spec_helper"

describe Soloist::RemoteConfig do
  let(:royal_crown_path) { File.expand_path("soloistrc", RSpec.configuration.tempdir) }
  let(:royal_crown) { Soloist::RoyalCrown.new(:path => royal_crown_path) }
  let(:remote) { Soloist::Remote.new("user", "host", "key") }
  let(:remote_config) { Soloist::RemoteConfig.new(royal_crown, remote) }

  before { remote.stub(:backtick => "", :system => 0) }

  def commands_for(method)
    [].tap do |commands|
      remote.stub(:system) { |c| commands << c; 0 }
      remote.stub(:backtick) { |c| commands << c; "" }
      remote_config.send(method)
    end
  end

  describe "#run_chef" do
    it "runs chef" do
      commands_for(:run_chef).last.should include "chef-solo"
    end
  end

  describe "#solo_rb_path" do
    it "sets the path to /etc/chef/solo.rb" do
      remote_config.solo_rb_path.should == "/etc/chef/solo.rb"
    end

    it "sets up solo.rb remotely" do
      commands_for(:solo_rb_path).last.should =~ /sudo -E tee \/etc\/chef\/solo\.rb$/
    end
  end

  describe "#node_json_path" do
    it "sets the path" do
      remote_config.node_json_path.should == "/etc/chef/node.json"
    end

    it "sets up node.json remotely" do
      commands_for(:node_json_path).last.should =~ /sudo -E tee \/etc\/chef\/node\.json$/
    end
  end

  describe "#chef_config_path" do
    it "sets the path" do
      remote_config.chef_config_path.should == "/etc/chef"
    end

    it "creates the path remotely" do
      commands_for(:chef_config_path).tap do |commands|
        commands.should have(1).command
        commands.first.should =~ /mkdir .*? -p \/etc\/chef$/
      end
    end
  end

  describe "#chef_cache_path" do
    it "sets the path" do
      remote_config.chef_cache_path.should == "/var/chef/cache"
    end

    it "creates the path remotely" do
      commands_for(:chef_cache_path).tap do |commands|
        commands.should have(1).command
        commands.first.should =~ /mkdir .*? -p \/var\/chef\/cache$/
      end
    end
  end

  describe "#cookbook_paths" do
    it "sets the path" do
      remote_config.cookbook_paths.should have(1).path
      remote_config.cookbook_paths.should =~ ["/var/chef/cookbooks"]
    end

    it "creates the path remotely" do
      commands_for(:cookbook_paths).tap do |commands|
        commands.should have(1).command
        commands.first.should =~ /mkdir .*? -p \/var\/chef\/cookbooks$/
      end
    end
  end
end

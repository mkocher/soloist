require "spec_helper"

describe Soloist::RemoteConfig do
  include Net::SSH::Test

  let(:tempdir) { Dir.mktmpdir("remote-config") }
  let(:royal_crown_path) { File.expand_path("soloistrc", tempdir) }
  let(:royal_crown) { Soloist::RoyalCrown.new(:path => royal_crown_path) }
  let(:remote) do
    Soloist::Remote.new(
      "user",
      "host",
      "key",
      :stdout => "",
      :stderr => ""
    ).tap { |r| r.stub(:connection => connection) }
  end
  let(:remote_config) { Soloist::RemoteConfig.new(royal_crown, remote) }

  describe "#solo_rb_path" do
    before do
      make_story_channel do |channel|
        channel.sends_exec 'mktemp\ -t\ solo.rb'
        channel.gets_data "/tmp/bummer"
      end
    end

    it "creates a file remotely" do
      remote.should_receive(:system!)
      remote_config.solo_rb_path.should == "/tmp/bummer"
    end

    it "dumps cookbook paths into the remote file" do
      remote.should_receive(:system!).with("echo 'cookbook_path []' | sudo -E tee /tmp/bummer > /dev/null")
      remote_config.solo_rb_path.should == "/tmp/bummer"
    end
  end

  describe "#node_json_path" do
    before do
      make_story_channel do |channel|
        channel.sends_exec 'mktemp\ -t\ node.json'
        channel.gets_data "/tmp/wat"
      end
    end

    it "creates a file remotely" do
      remote.should_receive(:system!)
      remote_config.node_json_path.should == "/tmp/wat"
    end

    it "dumps cookbook paths into the remote file" do
      remote.should_receive(:system!).with("echo '{\"recipes\"=>[]}' | sudo -E tee /tmp/wat > /dev/null")
      remote_config.node_json_path.should == "/tmp/wat"
    end
  end

  describe "#ensure_chef_path" do
    it "makes a directory remotely" do
      make_story_channel { |ch| ch.sends_exec 'sudo\ -E\ mkdir\ -p\ /var/chef/cache' }
      remote_config.ensure_chef_path
    end
  end
end

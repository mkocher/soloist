require "spec_helper"

RSpec.describe Soloist::Remote do
  include Net::SSH::Test

  subject { Soloist::Remote.new("user", "host", "key") }

  before { subject.connection = connection }

  shared_examples "ssh exec" do |command|
    let(:stdio) { double(:stdio, :<< => nil) }

    before { allow(subject).to receive_messages(:stdout => stdio, :stderr => stdio) }

    context "when properly connected" do
      before do
        make_story_channel do |channel|
          channel.sends_exec command
          channel.gets_data "endless bummer"
        end
      end

      it "returns standard output" do
        expect(stdio).to receive(:<<).with("endless bummer")
        described_function
      end

      it "sets the exit status" do
        expect { described_function }.to change { subject.exitstatus }.to(0)
      end
    end

    context "when execution fails" do
      before do
        make_story_channel do |channel|
          channel.sends_exec command,
          true, false
        end
      end

      it "raises ExecutionFailed" do
        expect { described_function }.to raise_error(Soloist::RemoteError)
      end
    end

    context "when the command exits" do
      before do
        make_story_channel do |channel|
          channel.sends_exec command
          channel.gets_extended_data "yodawg i put an error in your error"
          channel.gets_exit_status(127)
        end
        allow(subject).to receive(:stderr).and_return(stdio)
      end

      it "returns the exit status" do
        expect { described_function }.to change { subject.exitstatus }.to(127)
      end

      it "sends output to stderr" do
        expect(subject.stderr).to receive(:<<).with("yodawg i put an error in your error")
        described_function
      end
    end
  end

  describe "#backtick" do
    let(:described_function) { subject.backtick("not-a-japanese-band") }
    it_behaves_like "ssh exec", "not-a-japanese-band"

    it "returns stdout" do
      expect(subject).to receive(:exec) do
        subject.stdout << "wut"
      end
      expect(described_function).to eq("wut")
    end
  end

  describe "#system" do
    let(:described_function) { subject.system("i-blame-the-system-man") }
    it_behaves_like "ssh exec", "i-blame-the-system-man"

    it "returns the exit code" do
      subject.instance_variable_set(:@exitstatus, 666)
      expect(subject).to receive(:exec)
      expect(described_function).to eq(666)
    end
  end

  describe "#system!" do
    it "calls through to system" do
      expect(subject).to receive(:system).and_return(0)
      subject.system!("whatever-dude")
    end

    it "does not raise an exception if there is no error" do
      allow(subject).to receive(:system).and_return(0)
      expect { subject.system!("totally-chill-or-whatever") }.not_to raise_error
    end

    it "raises an exception if there is an error" do
      allow(subject).to receive(:system).and_return(1)
      expect { subject.system!("omg-wtf") }.to raise_error(Soloist::RemoteError)
    end
  end

  describe "#key" do
    let(:home_directory) { File.expand_path("~") }

    subject { Soloist::Remote.new("user", "host", "~/some_key") }

    it "matches a subdirectory in the home directory" do
      expect(subject.key).to match(%r|#{home_directory}/some_key|)
    end
  end

  describe "#upload" do
    it "runs rsync with the specified arguments" do
      expect(Kernel).to receive(:system).with("rsync -e 'ssh -i #{subject.key}' -avz --delete from user@host:to opts")
      subject.upload("from", "to", "opts")
    end
  end

  describe ".from_uri" do
    context "when a user is provided" do
      subject { Soloist::Remote.from_uri("destructo@1.2.3.4") }

      it "has a user equal to the user in the URI" do
        expect(subject.user).to eq("destructo")
      end

      it "has a host equal to the host in the URI" do
        expect(subject.host).to eq("1.2.3.4")
      end
    end

    context "when a user is not provided" do
      it "sets the correct user" do
        expect(Etc).to receive(:getlogin).and_return("jim-bob")
        expect(Soloist::Remote.from_uri("1.2.3.4").user).to eq("jim-bob")
      end
    end

    context "when a key is provided" do
      subject { Soloist::Remote.from_uri("dude@whatever", "/yo-some-key") }

      it "has a key equal to the provided key" do
        expect(subject.key).to eq("/yo-some-key")
      end
    end
  end
end

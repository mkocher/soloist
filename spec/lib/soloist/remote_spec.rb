require "spec_helper"

describe Soloist::Remote do
  include Net::SSH::Test

  subject do
    Soloist::Remote.new(
      :ip => "ip",
      :key => "key",
      :user => "user",
      :stdout => "",
      :stderr => ""
    ).tap { |r| r.stub(:connection => connection) }
  end

  shared_examples "ssh exec" do |command|
    def make_story_channel(&block)
      story do |session|
        channel = session.opens_channel
        block.call(channel)
        channel.gets_close
        channel.sends_close
      end
    end

    context "when properly connected" do
      before do
        make_story_channel do |channel|
          channel.sends_exec command
          channel.gets_data "endless bummer"
        end
      end

      it "returns standard output" do
        expect { described_function }.to change { subject.stdout.dup }
        subject.stdout.should == "endless bummer"
      end

      it "sets the exit status" do
        expect { described_function }.to change { subject.exitstatus }.to(0)
      end
    end

    context "when execution fails" do
      before do
        make_story_channel do |channel|
          channel.sends_exec command, true, false
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
      end

      it "returns the exit status" do
        expect { described_function }.to change { subject.exitstatus }.to(127)
      end

      it "sends output to stderr" do
        expect { described_function }.to change { subject.stderr.dup }
        subject.stderr.should == "yodawg i put an error in your error"
      end
    end
  end

  describe "#backtick" do
    let(:described_function) { subject.backtick("not-a-japanese-band") }
    it_behaves_like "ssh exec", "not-a-japanese-band"

    it "returns stdout" do
      subject.stdout << "wut"
      subject.should_receive(:exec)
      described_function.should == "wut"
    end
  end

  describe "#system" do
    let(:described_function) { subject.system("i-blame-the-system-man") }
    it_behaves_like "ssh exec", "i-blame-the-system-man"

    it "returns the exit code" do
      subject.instance_variable_set(:@exitstatus, 666)
      subject.should_receive(:exec)
      described_function.should == 666
    end
  end

  describe "#system!" do
    it "calls through to system" do
      subject.should_receive(:system).and_return(0)
      subject.system!("whatever-dude")
    end

    it "does not raise an exception if there is no error" do
      subject.stub(:system => 0)
      expect { subject.system!("totally-chill-or-whatever") }.not_to raise_error
    end

    it "raises an exception if there is an error" do
      subject.stub(:system => 1)
      expect { subject.system!("omg-wtf") }.to raise_error(Soloist::RemoteError)
    end
  end

  describe "#upload" do
    it "runs rsync with the specified arguments" do
      Kernel.should_receive(:system).with("rsync -e 'ssh -i key' -avz --delete from user@ip:to opts")
      subject.upload("from", "to", "opts")
    end
  end
end

require "spec_helper"

describe Soloist::KnownHosts do
  let(:known_hosts) { Tempfile.new([".", "known_hosts"]) }
  let(:key_blob) { "AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" }
  let(:key) { Net::SSH::Buffer.new(key_blob.unpack("m*").first).read_key }

  subject { Soloist::KnownHosts.new(known_hosts) }

  describe "#include?" do
    context "when the known hosts file does not have the host" do
      it "returns false" do
        subject.include?("1.2.3.4").should_not be
      end
    end

    context "when the known hosts file has the host" do
      before { subject.add("1.2.3.4", key) }

      it "returns true" do
        subject.include?("1.2.3.4").should be
      end
    end
  end

  describe "#add" do
    context "when the known hosts file does not have the host" do
      it "adds the host" do
        expect do
          subject.add("1.2.3.4", key)
        end.to change { subject.include?("1.2.3.4") }
      end
    end

    context "when the known hosts file has the host" do
      before { subject.add("1.2.3.4", key) }

      it "does not add the host" do
        expect do
          subject.add("1.2.3.4", key)
        end.not_to change { subject.include?("1.2.3.4") }
      end
    end
  end

  describe "#remove" do
    context "when the known hosts file does not have the host" do
      it "does not raise an exception" do
        expect { subject.remove("1.2.3.4") }.not_to raise_error
      end
    end

    context "when the known hosts file has the host" do
      before { subject.add("1.2.3.4", key) }

      it "removes the host" do
        expect do
          subject.remove("1.2.3.4")
        end.to change { subject.include?("1.2.3.4") }
      end

      context "when the known hosts file has other hosts" do
        before { subject.add("1.2.3.4,lard", key) }

        it "removes the host" do
          expect do
            subject.remove("1.2.3.4")
          end.to change { subject.include?("1.2.3.4") }.to(false)
        end
      end
    end
  end
end

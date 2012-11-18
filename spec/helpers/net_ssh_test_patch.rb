require "net/ssh/test"

class Net::SSH::Test::Packet
  alias :original_types :types
  def types
    @types ||= case @type
      when CHANNEL_EXTENDED_DATA then [:long, :long, :string]
      else original_types
      end
  end
end

class Net::SSH::Test::Script
  def gets_channel_extended_data(channel, data)
    events << Net::SSH::Test::RemotePacket.new(:channel_extended_data, channel.local_id, 1, data)
  end
end

class Net::SSH::Test::Channel
  def gets_extended_data(data)
    script.gets_channel_extended_data(self, data)
  end
end

class Net::SSH::Test::Kex
  def exchange_keys
    result = Net::SSH::Buffer.from(:byte, NEWKEYS)
    @connection.send_message(result)

    buffer = @connection.next_message
    raise Net::SSH::Exception, "expected NEWKEYS" unless buffer.type == NEWKEYS

    { :session_id        => "abc-xyz",
      :server_key        => OpenSSL::PKey::RSA.new(512),
      :shared_secret     => OpenSSL::BN.new("1234567890", 10),
      :hashing_algorithm => OpenSSL::Digest::SHA1 }
  end
end

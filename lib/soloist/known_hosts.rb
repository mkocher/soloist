require "net/ssh/known_hosts"

module Soloist
  class KnownHosts
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def include?(host)
      ! known_hosts.keys_for(host).empty?
    end

    def add(host, key)
      known_hosts.add(host, key) unless include?(host)
    end

    def remove(host)
      lines = File.readlines(path).delete_if do |line|
        line.strip.split(/\s+/).first.split(/,/).include?(host)
      end
      File.open(path, "w") { |file| lines.each { |line| file.puts(line) } }
    end

    private
    def known_hosts
      @known_hosts ||= Net::SSH::KnownHosts.new(path)
    end
  end
end

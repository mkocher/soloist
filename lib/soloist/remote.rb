require "net/ssh"
require "shellwords"
require "etc"

module Soloist
  class RemoteError < RuntimeError; end

  class Remote
    attr_reader :user, :host, :key, :timeout, :stdout, :stderr, :exitstatus
    attr_writer :connection

    def self.from_uri(uri, key = "~/.ssh/id_rsa")
      parsed = URI.parse("ssh://#{uri}")
      new(parsed.user || Etc.getlogin, parsed.host, key)
    end

    def initialize(user, host, key, options = {})
      @user = user
      @host = host
      @key = key
      @timeout = options[:timeout] || 10000
      @stdout = options[:stdout] || STDOUT
      @stderr = options[:stderr] || STDERR
    end

    def backtick(command)
      exec(Shellwords.escape(command))
      stdout
    end

    def system(command)
      exec(Shellwords.escape(command))
      exitstatus
    end

    def system!(command)
      system(command).tap do |status|
        raise RemoteError.new("#{command} exited #{status}") unless status == 0
      end
    end

    def upload(from, to, opts = "--exclude .git")
      Kernel.system("rsync -e 'ssh -i #{key}' -avz --delete #{from} #{user}@#{host}:#{to} #{opts}")
    end

    private
    def connection
      @connection ||= Net::SSH.start(host, user, :keys => [key], :timeout => timeout)
    end

    def exec(command)
      connection.open_channel do |channel|
        channel.exec(command) do |stream, success|
          raise RemoteError.new("Could not run #{command}") unless success
          stream.on_data { |_, data| stdout << data }
          stream.on_extended_data { |_, type, data| stderr << data }
          stream.on_request("exit-status") { |_, data| @exitstatus = data.read_long }
        end
      end
      connection.loop
      @exitstatus ||= 0
    end
  end
end

require "net/ssh"
require "shellwords"

module Soloist
  class RemoteError < RuntimeError; end

  class Remote
    attr_reader :ip, :key, :user, :timeout, :stdout, :stderr, :exitstatus
    attr_writer :connection

    def initialize(options = {})
      @ip = options.fetch(:ip)
      @key = options.fetch(:key)
      @user = options.fetch(:user)
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
      Kernel.system("rsync -e 'ssh -i #{key}' -avz --delete #{from} #{user}@#{ip}:#{to} #{opts}")
    end

    private
    def connection
      @connection ||= Net::SSH.start(ip, user, :keys => [key], :timeout => timeout)
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

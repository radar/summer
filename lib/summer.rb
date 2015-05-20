require 'socket'
require 'openssl'
require 'fileutils'
require 'yaml'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/object/try'

Dir[File.dirname(__FILE__) + '/ext/*.rb'].each { |f| require f }

require File.dirname(__FILE__) + "/summer/handlers"

module Summer
  class Connection
    include Handlers
    attr_accessor :connection, :ready, :started, :config, :server, :port
    def initialize(server, port=6667, dry=false)
      @ready = false
      @started = false

      @server = server
      @port = port

      trap(:INT) do
        puts "Shutting down..."
        FileUtils.rm_rf(pid_file)
        exit
      end

      trap(:HUP) do
        puts "Restarting..."
        FileUtils.rm_rf(pid_file)
        exec "/usr/bin/env ruby #{$0} #{ARGV[0]}"
      end

      load_config
      File.open(pid_file, "w+") do |f|
        f.write Process.pid
      end
      connect!

      unless dry
        loop do
          startup! if @ready && !@started
          parse(@connection.gets)
        end
      end
    end

    private

    def load_config
      @config = HashWithIndifferentAccess.new(YAML::load_file(File.dirname($0) + "/config/summer.yml"))
    end

    def connect!
      @connection = TCPSocket.open(server, port)
      @connection = OpenSSL::SSL::SSLSocket.new(@connection).connect if config[:use_ssl]
      response("USER #{config[:nick]} #{config[:nick]} #{config[:nick]} #{config[:nick]}")
      response("PASS #{config[:server_password]}") if config[:server_password]
      response("NICK #{config[:nick]}")
    end


    # Will join channels specified in configuration.
    def startup!
      @started = true
      try(:did_start_up)

      if config['nickserv_password']
        privmsg("identify #{config['nickserv_password']}", "nickserv")
        # Wait 10 seconds for nickserv to get back to us.
        Thread.new do
          sleep(10)
          finalize_startup
        end
      else
        finalize_startup
      end
    end

    def finalize_startup
      config[:channels] ||= []
      (config[:channels] << config[:channel]).compact.each do |channel|
        join(channel)
      end
    end

    # Go somewhere.
    def join(channel)
      response("JOIN #{channel}")
    end

    # Leave somewhere
    def part(channel)
      response("PART #{channel}")
    end

    # What did they say?
    def parse(message)
      puts "<< #{message.to_s.strip}"
      words = message.split(" ")
      sender = words[0]
      raw = words[1]
      channel = words[2]
      # Handling pings
      if /^PING (.*?)\s$/.match(message)
        response("PONG #{$1}")
      # Handling raws
      elsif /\d+/.match(raw)
        send("handle_#{raw}", message) if raws_to_handle.include?(raw)
      # Privmsgs
      elsif raw == "PRIVMSG"
        message = words[3..-1].clean
        # Parse commands
        if /^!(\w+)\s*(.*)/.match(message) && respond_to?("#{$1}_command")
          try("#{$1}_command", parse_sender(sender), channel, $2)
        # Plain and boring message
        else
          sender = parse_sender(sender)
          method, channel = channel == me ? [:private_message, sender[:nick]]  : [:channel_message, channel]
          try(method, sender, channel, message)
        end
      # Joins
      elsif raw == "JOIN"
        try(:join_event, parse_sender(sender), channel)
      elsif raw == "PART"
        try(:part_event, parse_sender(sender), channel, words[3..-1].clean)
      elsif raw == "QUIT"
        try(:quit_event, parse_sender(sender), words[2..-1].clean)
      elsif raw == "KICK"
        try(:kick_event, parse_sender(sender), channel, words[3], words[4..-1].clean)
        join(channel) if words[3] == me && config[:auto_rejoin]
      elsif raw == "MODE"
        try(:mode_event, parse_sender(sender), channel, words[3], words[4..-1].clean)
      end

    end

    def parse_sender(sender)
      nick, hostname = sender.split("!")
      { :nick => nick.clean, :hostname => hostname }
    end

    # These are the raws we care about.
    def raws_to_handle
      ["422", "376", "433"]
    end

    def privmsg(message, to)
      response("PRIVMSG #{to} :#{message}")
    end

    # Output something to the console and to the socket.
    def response(message)
      puts ">> #{message.strip}"
      @connection.puts(message)
    end

    def me
      config[:nick]
    end

    def log(message)
      File.open(config[:log_file]) { |file| file.write(message) } if config[:log_file]
    end

    def pid_file
      "/tmp/summer-#{config[:nick]}.pid"
    end

    def nickserv_authed?
      @nickserv_authed
    end

    # Nickname in use
    def handle_433(message)
      response("NICK #{config[:alternate_nick]}") if config[:alternate_nick].present?
    end

  end

end

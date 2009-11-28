require 'socket'
require 'yaml'
require 'active_support'

require File.dirname(__FILE__) + "/summer/handlers"

module Summer
  class Connection
    include Handlers
    attr_accessor :connection, :ready, :started, :config
    def initialize(server, port=6667)
      
      # Ready is set when the bot receives the end of the MOTD, or missing MOTD message
      @ready = false
      
      # Started is set when +startup+ completes.
      @started = false
      
      @config = HashWithIndifferentAccess.new(YAML::load_file(File.dirname($0) + "/config/summer.yml"))
      
      @connection = TCPSocket.open(server, port)
      
      @connection.puts("USER #{config[:nick]} #{config[:nick]} #{config[:nick]} #{config[:nick]}")
      @connection.puts("NICK #{config[:nick]}")
      loop do
        startup! if @ready && !@started
        parse(@connection.gets)
      end
    end
    
    private
    
    # Will join channels specified in configuration.
    def startup!
      (@config[:channels] << @config[:channel]).compact.each do |channel|
        join(channel)
      end
      @started = true
      try(:did_start_up)
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
      puts "<< #{message.strip}"
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
        message = words[3..-1].join(" ").gsub(/^:/, '')
        # Parse commands
        if /^!(\w+)\s*(.*)/.match(message) && respond_to?("#{$1}_command")
g          try("#{$1}_command", parse_sender(sender), channel, $2)
        # Plain and boring message
        else
          method = channel == me ? :did_receive_private_message : :did_receive_channel_message
          try(method, parse_sender(sender), channel, message) if respond_to?(method)
        end
      end
    
    end
    
    def parse_sender(sender)
      nick, hostname = sender.split("!")
      { :nick => nick.gsub(/^:/, ''), :hostname => hostname }
    end
    
    # These are the raws we care about.
    def raws_to_handle
      ["422", "376"]
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
    
  end
  
end

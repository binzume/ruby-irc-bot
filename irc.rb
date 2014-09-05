require 'time'
require 'net/irc'
require 'kconv'
require 'digest/md5'

def irc_connect servers, bot
  servers.map{|server|
    s = IrcServer.new(server)
    client = s.connect

    client.add_bot(bot) if bot

    t = Thread.new do
      client.start
      puts "IRC client finished."
    end
    s
  }
end

class IrcServer
  attr_accessor :config, :id
  attr_reader :client

  def initialize config, id = nil
    @config = config
    @id = id || Digest::MD5.hexdigest(config['server'] + ":" + config['nick'])
  end

  def connected
    @client && @client.connected
  end

  def connect
    host = @config["server"].split(':')[0]
    port = (@config['server'].split(':')[1]||6667).to_i
    @client = IrcClient.new(host, port, {
                  :nick => @config['nick'],
                  :user => @config['user'],
                  :real => @config['name'],
                  :pass => @config['pass'],
                  :use_ssl => @config['use_ssl'],
                })
    @config["channels"].each{|ch|
      @client.add_channel(ch)
    }

    @client
  end

  def disconnect
    if @client && @client.connected
      @client.finish
      @client = nil
    end
  end
end

class IrcChannel < Channel
  include Net::IRC::Constants
  attr_reader :client

  def initialize(name, client)
    @type = 'IRC'
    @name = name
    @client = client
    @connected = true
    @members = Set.new
  end

  def send msg
    @client.post(NOTICE, @name, msg) if @connected
  end

  def leave
    @client.post(PART, @name)
    @connected = false
  end

  def request_names
    @client.post(NAMES, @name)
  end

end

class IrcClient < Net::IRC::Client
  attr :connected
  attr_reader :channels


  def initialize(*args)
    super
    @connected = false
    @channels = {}
    @auto_join = true
  end

  # BUG: only use last one.
  def add_bot b
    @bot = b
  end

  def add_channel name
    @channels[name] = IrcChannel.new(name, self)
    @channels[name].connected = false
  end

  def on_message(m)
    @bot.on_irc_message(m) if @bot
    #p m
    if m.command == JOIN && m.prefix == @prefix
      ch = channel(m[0])
      ch.connected = true
      @bot.on_join(ch) if @bot
    end
    if m.command == JOIN && m.prefix != @prefix
      ch = channel(m[0])
      ch.members.add(m.prefix.nick)
      @bot.on_join_user(ch, m.prefix.nick) if @bot
    end
    if m.command == PART && m.prefix == @prefix
      ch = channel(m[0])
      ch.connected = false
      @bot.on_leave(ch) if @bot
    end
    if m.command == PART && m.prefix != @prefix
      ch = channel(m[0])
      ch.members.delete(m.prefix.nick)
      @bot.on_part_user(ch, m.prefix.nick) if @bot
    end
    if m.command == KICK
      ch = channel(m[0])
      ch.connected = false
      @bot.on_leave(ch) if @bot
    end
    if m.command == INVITE
      post JOIN, m[1] if @auto_join
    end
    if m.command == RPL_NAMREPLY
      ch = channel(m[2])
      m.params[3].split(/\s/).each{|n|
        ch.members << n.gsub(/[+@:]/,"")
      }
    end
  end

  def channel name
      ch = @channels[name] || IrcChannel.new(name,self)
      @channels[name] = ch
      ch
  end

  def on_rpl_welcome(m)
    super
    @channels.each_value {|ch|
      post JOIN, ch.name
    }
    @bot.on_start unless @connected
    @connected = true
  end

  def on_privmsg(m)
    ch = @channels[m[0]] || IrcChannel.new(m[0],self)
    # m = [channel, message]
    @bot.on_message(ch, m[1].toutf8, m.prefix)
  end

  def send_notice(msg)
    post(NOTICE, @channels[0], msg)
  end

  def on_connected
    if @opts.use_ssl
      puts "Using SSL"
      require 'openssl'
      ssl_context = OpenSSL::SSL::SSLContext.new
      # ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @socket = OpenSSL::SSL::SSLSocket.new(@socket, ssl_context)
      @socket.sync = true
      @socket.connect
    end
    super
  end

  def finish
    begin
      post(QUIT) if @connected
    rescue Exception => e
        warn e
        warn e.backtrace.join("\r\t")
    end
    @connected = false
    @channels.each_value {|ch|
      @bot.on_leave(ch) if @bot
    }
    super
  end

  def post(command, *params)
    super
  end
end


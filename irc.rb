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
    port = (@config['server'].split(':')[1]||6664).to_i
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

  def initialize(name, client)
    @type = 'IRC'
    @name = name
    @client = client
    @connected = true
  end

  def send msg
    @client.post(NOTICE, @name, msg)
  end

  def leave
    @client.post(LEAVE, @name)
    @connected = false
  end

  def request_names
    @client.post(NAMES, @name)
  end

end

class IrcClient < Net::IRC::Client
  attr :connected


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
    #p m
    if m.command == JOIN
      ch = @channels[m[0]] || IrcChannel.new(m[0],self)
      ch.connected = true
      @channels[m[0]] = ch
      @bot.on_join(ch) if @bot
    end
    if m.command == KICK
      ch = @channels[m[0]] || IrcChannel.new(m[0],self)
      ch.connected = false
      @bot.on_leave(ch) if @bot
    end
    if m.command == INVITE
      post JOIN, m[1] if @auto_join
    end
  end

  def on_rpl_welcome(m)
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
    post(QUIT) if @connected
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


require 'json'
require 'time'

class Channel
  attr_reader :name, :type
  attr_accessor :connected

  def send msg
  end

  def leave
  end
end

class Bot
  attr_reader :logs

  def initialize
    @channels = []
    @logs = []
    @max_logs = 1000
    @conf = open("conf/bot.json") {|f|
      JSON.parse(f.read)
    }
  end

  def on_start
    log "Start."
  end

  def on_message ch,prefix,message
    log "#{ch}, #{prefix} : #{message}"
    if message =~/debug_conf/
      debug_conf
    end
  end

  def on_join ch
    @channels << ch
    ch.request_names
  end

  def on_leave ch
    @channels.delete(ch)
  end

  def on_tick
  end

  def debug_conf
    if @channels.length > 0
      @conf.channels = @channels.map{|c|c.name}
    end
    puts JSON.pretty_generate(@conf)
  end

  def channels
    @channels
  end

  def log msg
    puts msg
    @logs << {:time => Time.now ,:message => msg}
    if @logs.length > @max_logs
      @logs = @logs.slice(@logs.length-@max_logs, @max_logs)
    end
  end

end

if $0 == __FILE__
  # sample
  b = Bot.new
  b.on_start
end

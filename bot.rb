require 'json'
require 'time'

class Channel
  attr_reader :name, :type, :members
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
    @conf = if File.exist?("conf/bot.json")
      open("conf/bot.json") {|f|
        JSON.parse(f.read)
      }
    end
  end

  def channels
    @channels
  end

  def on_start
    log "Start."
  end

  def on_message ch, message, from
    log "#{ch.name}, #{from} : #{message}"
    if message =~/foo/
      ch.send("bar")
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

  def on_join_user ch, nick
  end

  def on_part_user ch, nick
  end

  def on_irc_message m
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

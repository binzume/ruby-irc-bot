require 'json'
require 'time'
require_relative 'confmanager'
require_relative 'scheduler'
require_relative 'keywords'

class Channel
  attr_reader :name, :type, :members
  attr_accessor :connected

  def send msg
  end

  def leave
  end
end

class Bot
  attr_reader :logs, :keywords, :scheduler

  def initialize
    @config = FileConfig.new("conf/config.json")
    @scheduler = Scheduler.new(@config)
    @keywords = Keywords.new(@config)
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
  end

  def on_message ch, message, from
    log "#{ch.name}, #{from} : #{message}"
    @keywords.match?(message) {|keyword|
      _on_event keyword
    }
  end

  def on_join ch
    @channels << ch
    ch.request_names
  end

  def on_leave ch
    @channels.delete(ch)
  end

  def on_tick
    @scheduler.each_current(Time.now) {|sch|
      _on_event sch
    }
  end

  def _on_event item
    channels = if item.channels.include?('*')
      @channels
    else
      @channels.select{|ch| item.channels.include?(ch.name) }
    end
    case item.message_type
    when 'EVENT'
      if item.is_a?(Schedule)
        on_schedule_event item, channels
      else
        on_keyword_event item, channels
      end
    else
      channels.each {|ch|
        ch.send(item.message) if ch.connected
      }
    end
  end

  def on_join_user ch, nick
  end

  def on_part_user ch, nick
  end

  def on_irc_message m
  end

  def on_schedule_event event, channels
    log("Scheduled Event: #{event.message}")
  end

  def on_keyword_event event, channels
    log("Keyword Event: #{event.message}")
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

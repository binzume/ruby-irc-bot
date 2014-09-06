require 'json'
require 'time'
require_relative 'scheduler'

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
    @scheduler = Scheduler.new
    @channels = []
    @logs = []
    @keywords = []
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
      channels = if sch.channels.include?('*')
        @channels
      else
        @channels.select{|ch| sch.channels.include?(ch.name) }
      end
      case sch.type
      when 'EVENT'
        on_schedule_event sch, channels
      else
        channels.each {|ch|
          ch.send(sch.message) if ch.connected
        }
      end
    }
  end

  def on_join_user ch, nick
  end

  def on_part_user ch, nick
  end

  def on_irc_message m
  end

  def on_schedule_event sch, channels
    log("Scheduled Event: #{sch.message}")
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

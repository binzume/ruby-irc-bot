require 'time'

class Schedule
  attr_accessor :year, :month, :day, :hour, :min, :wday, :type, :message, :channels

  def initialize(opt)
    @year = opt[:year]
    @month = opt[:month]
    @day = opt[:day]
    @hour = opt[:hour]
    @min = opt[:min]
    @wday = opt[:wday]
    @type = opt[:type]
    @message = opt[:message]
    @channels = opt[:channels]
  end

  def now?(now = Time.now)
    [
      now.year, now.month, now.day, now.hour, now.min, now.wday
    ].zip([
      @year, @month, @day, @hour, @min, @wday
    ]).all?{|t,s|
      compare(t,s)
    }
  end

  private
  def compare(t,s)
    s.split(',').any?{|ss|
      case ss
      when '*'
        true
      when /^\d+$/
        t == ss.to_i
      when /^(\d+)-(\d+)$/
        t.between?($1.to_i, $2.to_i)
      when /\*\/(\d+)$/
        t % $1.to_i == 0
      else
        false
      end
    }
  end
end

class Scheduler
  attr_accessor :schedules
  def initialize
    @schedules = []
  end

  def schedule(sch)
    @schedules << sch
  end

  def each_current time, &block
    @schedules.each{|sch|
      if sch.now?(time)
        block.call(sch)
      end
    }
  end

end


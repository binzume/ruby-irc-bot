require 'time'
require 'securerandom'

class Schedule
  attr_accessor :id, :year, :month, :day, :hour, :min, :wday, :message_type, :message, :channels

  def initialize(opt)
    @id = opt[:id] || SecureRandom.uuid
    @year = opt[:year]
    @month = opt[:month]
    @day = opt[:day]
    @hour = opt[:hour]
    @min = opt[:min]
    @wday = opt[:wday]
    @message_type = opt[:message_type]
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

  def to_h
    { id: @id, year: @year, month: @month, day: @day, hour: @hour, min: @min, wday: @wday,
      message_type: @message_type, message: @message, channels: @channels }
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
  def initialize(config = nil)
    @schedules = []
    @config = config
    if @config
      @schedules = @config.map_get('schedules').map{|id, sch|
        Schedule.new(Hash[sch.map{|k, v| [k.to_sym, v] }])
      }
    end
  end

  def schedule(sch)
    @schedules << sch
    @config.map_field_set('schedules', sch.id, sch.to_h) if @config
    @config.save! if @config
  end

  def delete(id)
    @schedules.delete_if{|item| item.id == id}
    @config.map_field_del('schedules', id) if @config
    @config.save! if @config
  end

  def each_current time, &block
    @schedules.each{|sch|
      if sch.now?(time)
        block.call(sch)
      end
    }
  end

end


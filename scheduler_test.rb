#!/usr/bin/ruby

require 'test/unit'
require_relative 'confmanager'
require_relative 'scheduler'

class SchedulerTest < Test::Unit::TestCase
  def setup
    @config = FileConfig.new(nil)
    @scheduler = Scheduler.new(@config)
  end

  def test_each_current
    params = {year: '2013', month: '9', day: '1', hour: '*', min: '*', wday: '*',
      message_type: 'NORMAL', message: 'aaaa', channels: []}
    @scheduler.schedule(Schedule.new(params))
    @scheduler.each_current(Time.parse('2013-09-01T10:10:10')) {|sch|
      p sch
    }
  end

end


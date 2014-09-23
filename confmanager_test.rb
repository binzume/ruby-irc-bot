#!/usr/bin/ruby

require 'test/unit'
#require_relative 'redisconfmanager'
require_relative 'confmanager'

class ConfigTest < Test::Unit::TestCase
  def setup
    #@config = RedisConf.new("localhost", '')
    @config = FileConfig.new("aaa.txt")
    @config.clear!
  end

  def test_kv
    @config.set('hoge', 123456)
    @config.set('fuga', "asdfghj")
    @config.set('foo', nil)
    @config.get('fuga')
    @config.save!
  end

  def test_list
    @config.set('list1', ["aaa","bbb","vvv"])
    p @config.list_get('list1')
    assert(@config.list_get('empty') == [])
    @config.list_add('list1', "ccc")
    assert(@config.list_get('list1').last == "ccc")
  end

end


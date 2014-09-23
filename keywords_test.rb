#!/usr/bin/ruby

require 'test/unit'
require_relative 'confmanager'
require_relative 'keywords'

class ConfigTest < Test::Unit::TestCase
  def setup
    @config = FileConfig.new(nil)
    @keywords = Keywords.new(@config)
  end

  def test_keyword
    params = {matcher: 'NORMAL', word: 'hoge', message_type: 'NORMAL', message: 'aaaa', channels: []}
    @keywords.register(Keyword.new(params))
    @keywords.match?("hoge fuga") {|k|
      assert(k.word == "hoge")
      p k
    }
    @keywords2 = Keywords.new(@config)
    assert(@keywords2.keywords.length == 1)

  end

end


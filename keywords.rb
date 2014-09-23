require 'securerandom'

class Keyword
  attr_accessor :id, :matcher, :word, :message_type, :message, :channels

  def initialize(opt)
    @id = opt[:id] || SecureRandom.uuid
    @matcher = opt[:matcher]
    @word = opt[:word]
    @message_type = opt[:message_type]
    @message = opt[:message]
    @channels = opt[:channels]
  end

  def match?(msg)
    msg.include?(@word)
  end

  def to_h
    { id: @id, matcher: @matcher, word: @word, message_type: @message_type, message: @message, channels: @channels }
  end
end

class Keywords
  attr_accessor :keywords
  def initialize(config = nil)
    @keywords = []
    @config = config
    if @config
      @keywords = @config.map_get('keywords').map{|id, word|
        Keyword.new(Hash[word.map{|k, v| [k.to_sym, v] }])
      }
    end
  end

  def register(keyword)
    @keywords << keyword
    @config.map_field_set('keywords', keyword.id, keyword.to_h) if @config
    @config.save! if @config
  end

  def delete(id)
    @keywords.delete_if{|item| item.id == id}
    @config.map_field_del('keywords', id) if @config
    @config.save! if @config
  end

  def match? msg, &block
    @keywords.each{|keyword|
      if keyword.match?(msg)
        block.call(keyword)
      end
    }
  end
end


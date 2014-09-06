
require_relative 'bot'

class SampleBot < Bot
  attr_reader :logs

  def on_start
    super
    log "Start."
  end

  def on_message ch, message, from
    log "#{ch.name}, #{from} : #{message}"
    if message =~/foo/
      ch.send("bar")
    end

  end

  def on_tick
    super
  end

  def on_join_user ch, nick
    ch.send("hello, #{nick}!")
  end

end


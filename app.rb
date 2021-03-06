#!/usr/bin/ruby -Ku
# encoding: utf-8

require 'sinatra/base'
require 'json'
require_relative 'bot'
require_relative 'irc'

class IrcBotWeb < Sinatra::Base
  use Rack::Auth::Basic do |username, password|
    (!settings.pass) || username == 'admin' && password == settings.pass
  end

  get '/status' do
    {:status => 'ok'}.to_json
  end

  get '/api/logs' do
    {:status => 'ok', :logs => settings.bot.logs }.to_json
  end

  get '/api/channels' do
    channels = settings.servers.map{|s|
      if s.client
        s.client.channels.values.map{|c|
          {:id => c.name, :server_id => s.id, :name => c.name, :type => c.type, :connected => c.connected}
        }
      else
        []
      end
    }.flatten
    p channels
    {:status => 'ok', :channels => channels }.to_json
  end

  get '/api/servers' do
    {:status => 'ok', :servers => settings.servers.map{|s| s.config.merge({:id => s.id, :connected => s.connected})} }.to_json
  end

  get '/api/servers/:id' do
    s = settings.servers.find{|s| s.id == params[:id] }
    {:status => 'ok', :server => s.config.merge({:id => s.id, :connected => s.connected})}.to_json
  end

  post '/api/servers/:id/-connect' do
    s = settings.servers.find{|s| s.id == params[:id] }
    if s
      unless s.client
        client = s.connect
        client.add_bot(settings.bot)
        Thread.new do
          client.start
          puts "IRC client finished."
        end
      end

      {:status => 'ok', :server => s.config.merge({:id => s.id, :connected => s.connected})}.to_json
    else
      {:status => 'error', :code => 404}
    end
  end

  post '/api/servers/:id/-disconnect' do
    s = settings.servers.find{|s| s.id == params[:id] }
    if s
      s.disconnect
      {:status => 'ok', :server => s.config.merge({:id => s.id, :connected => s.connected})}.to_json
    else
      {:status => 'error', :code => 404}
    end
  end

  delete '/api/servers/:id' do
    s = settings.servers.find{|s| s.id == params[:id] }
    if s
      s.disconnect
      settings.servers.delete(s)
      {:status => 'ok', :server => s.config.merge({:id => s.id, :connected => s.connected})}.to_json
    else
      {:status => 'error', :code => 404}
    end
  end

  post '/api/servers/-create' do
    config = {
      "server" => params["irc_server"],
      "use_ssl" => params["irc_use_ssl"] == "on",
      "nick" => params["irc_nick"],
      "name" => params["irc_name"],
      "user" => params["irc_user"],
      "pass" => params["irc_pass"].empty? ? nil : params["irc_pass"],
      "channels" => params["irc_channels"].empty? ? [] : params["irc_channels"].split("\n").map{|c|c.strip}
    }
    s = IrcServer.new(config)
    settings.servers << s
    {:status => 'ok', :id => s.id}.to_json
  end

  post '/api/servers/:id' do
    s = settings.servers.find{|s| s.id == params[:id] }
    if s
      s.config["nick"] = params["irc_nick"]
      s.config["use_ssl"] = params["irc_use_ssl"] == "on"
      s.config["name"] = params["irc_name"]
      s.config["user"] = params["irc_user"]
      s.config["pass"] = params["irc_pass"].empty? ? nil : params["irc_pass"]
      s.config["channels"] = params["irc_channels"].empty? ? [] : params["irc_channels"].split("\n").map{|c|c.strip}
      {:status => 'ok', :server => s.config.merge({:id => s.id, :connected => s.connected})}.to_json
    else
      {:status => 'error', :code => 404}
    end
  end

  delete '/api/servers/:id/channels/:name' do
    s = settings.servers.find{|s| s.id == params[:id] }
    if s && s.client
      ch = s.client.channels.find{|ch| ch.name = params[:name]}
      ch.leave() if ch
      {:status => 'ok'}
    else
      {:status => 'error', :code => 404}
    end
  end

  get '/api/schedules' do
    schedules = settings.bot.scheduler.schedules.map{|s| s.to_h}
    {:status => 'ok', :schedules => schedules}.to_json
  end

  get '/api/schedules/:id' do
    schedule = settings.bot.scheduler.schedules.find{|s| s.id == params[:id] }
    halt 404, {:status => 'NOT_FOUND', :message => 'Not Found.'}.to_json unless schedule
    {:status => 'ok', :schedule => schedule.to_h }.to_json
  end

  post '/api/schedules/-create' do
    halt 400, {:status => 'error', :message => 'param: year'}.to_json unless params["year"] && params["year"]=~/^[\d,\-\*\/]+$/
    halt 400, {:status => 'error', :message => 'param: month'}.to_json unless params["month"] && params["month"]=~/^[\d,\-\*\/]+$/
    halt 400, {:status => 'error', :message => 'param: day'}.to_json unless params["day"] && params["day"]=~/^[\d,\-\*\/]+$/
    halt 400, {:status => 'error', :message => 'param: wday'}.to_json unless params["wday"] && params["wday"]=~/^[\d,\-\*\/]+$/
    halt 400, {:status => 'error', :message => 'param: channels'}.to_json unless params["channels"]
    settings.bot.scheduler.schedule(Schedule.new({
      :year => params["year"],
      :month => params["month"],
      :day => params["day"],
      :wday => params["wday"],
      :hour => params["hour"],
      :min => params["min"],
      :message_type => params["message_type"],
      :message => params["message"],
      :channels => params["channels"].split(','),
    }))
    {:status => 'ok'}.to_json
  end

  delete '/api/schedules/:id' do
    schedule = settings.bot.scheduler.schedules.find{|s| s.id == params[:id] }
    halt 404, {:status => 'NOT_FOUND', :message => 'Not Found.'}.to_json unless schedule
    settings.bot.scheduler.delete(params[:id])
    {:status => 'ok'}.to_json
  end

  get '/api/keywords' do
    keywords = settings.bot.keywords.keywords
    {:status => 'ok', :keywords => keywords.map{|k|k.to_h}}.to_json
  end

  get '/api/keywords/:id' do
    keyword = settings.bot.keywords.keywords.find{|s| s.id == params[:id] }
    halt 404, {:status => 'NOT_FOUND', :message => 'Not Found.'}.to_json unless keyword
    {:status => 'ok', :keyword => keyword.to_h}.to_json
  end

  post '/api/keywords/-create' do
    halt 400, {:status => 'error', :message => 'param: message'}.to_json unless params["message"]
    halt 400, {:status => 'error', :message => 'param: channels'}.to_json unless params["channels"]
    keyword = Keyword.new({
      :matcher => params["matcher"],
      :word => params["word"],
      :message_type => params["message_type"],
      :message => params["message"],
      :channels => params["channels"].split(','),
    })
    settings.bot.keywords.register(keyword)
    {:status => 'ok', :keyword => keyword.to_h}.to_json
  end

  delete '/api/keywords/:id' do
    keyword = settings.bot.keywords.keywords.find{|s| s.id == params[:id] }
    halt 404, {:status => 'NOT_FOUND', :message => 'Not Found.'}.to_json unless keyword
    settings.bot.keywords.delete(params[:id])
    {:status => 'ok'}.to_json
  end

  get '/*' do
    file = if params[:splat][0] == ""
      "index.html"
    else
      params[:splat][0]
    end
    puts file
    send_file('public/' + file,  {:stream => false})
  end

end

require_relative 'samplebot'
bot = SampleBot.new

# tick
t = Thread.new do
  loop do
    sleep(60)
    bot.on_tick()
  end
end


# IRC
servers = if File.exist?("conf/servers.json")
  open("conf/servers.json") {|f|
    JSON.parse(f.read)
  }
else
  {"servers" => []}
end
irc_servers = irc_connect servers["servers"], bot

# web
IrcBotWeb.set :servers, irc_servers
IrcBotWeb.set :bot, bot
IrcBotWeb.set :pass, "hoge"
IrcBotWeb.run! :host => 'localhost', :port => (ARGV[0] || 4567)


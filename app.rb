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
    {:status => 'ok', :channels => settings.bot.channels.map{|c|{:id => 0, :name => c.name, :type => c.type, :connected => c.connected}} }.to_json
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
      "channels" => []
    }
    s = IrcServer.new(config)
    settings.servers << s
    {:status => 'ok', :id => s.id}.to_json
  end

  post '/api/servers/:id' do
    s = settings.servers.find{|s| s.id == params[:id] }
    if s
      s.config["nick"] = params["irc_nick"]
      s.config["use_ssl"] = params["irc_use_ssl"] == "on",
      s.config["name"] = params["irc_name"]
      s.config["user"] = params["irc_user"]
      s.config["pass"] = params["irc_pass"].empty? ? nil : params["irc_pass"]
      {:status => 'ok', :server => s.config.merge({:id => s.id, :connected => s.connected})}.to_json
    else
      {:status => 'error', :code => 404}
    end
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

bot = Bot.new

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


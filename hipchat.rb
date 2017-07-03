#!/usr/bin/env ruby
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'hipchat'
require 'timeout'
class HipChatNotif < Sensu::Handler
  option :room,
         :description => 'HipChat Room Name to send messages to',
         :short => '-r ROOM',
         :long => '--room ROOM',
         :default => 'Sensu Test'
  def event_name
    @event['client']['name'] + '/' + @event['check']['name']
  end
  def handle
    server_url = settings["hipchat"]["server_url"]
    hipchatmsg = HipChat::Client.new(settings["hipchat"]["apikey"],:api_version => 'v2',:server_url=>server_url)
    room = settings["hipchat"]["room"]
    from = settings["hipchat"]["from"]
    message = @event['check']['notification'] || @event['check']['output']
    begin
      timeout(3) do
        if @event['action'].eql?("resolve")
          hipchatmsg[room].send(from,
                "RESOLVED - [#{event_name}] - #{message}.", :color => 'green')
        elsif @event['check']['status'] == 1
          hipchatmsg[room].send(from, "WARNING - [#{event_name}] - #{message}.",
                :color => 'yellow')
        else
          hipchatmsg[room].send(from, "ALERT - [#{event_name}] - #{message}.",
                :color => 'red', :notify => true)
        end
      end
    rescue Timeout::Error
      puts "hipchat -- timed out while attempting to message #{room}"
    end
  end
end
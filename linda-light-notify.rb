#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/rocketio/linda/client'
$stdout.sync = true

url =     ENV["LINDA_BASE"] || ARGV.shift || "http://localhost:5000"
spaces = (ENV["LINDA_SPACES"]||ENV["LINDA_SPACE"]||"test").split(/,/)
threshold = (ENV["LIGHT_THRESHOLD"] || 30).to_i
puts "light threshold : #{threshold}"
puts "connecting.. #{url}"
linda = Sinatra::RocketIO::Linda::Client.new url

tss = {}
spaces.each do |i|
  tss[i] = linda.tuplespace[i]
end
puts "spaces : #{tss.keys}"

lasts = Hash.new{|h,k| h[k] = Hash.new }

linda.io.on :connect do  ## RocketIO's "connect" event
  puts "connect!! <#{linda.io.session}> (#{linda.io.type})"
  tss.each do |name, ts|
    ts.watch ["sensor", "light"]{|tuple|
      next unless tuple.size == 3 and (tuple[2].to_s =~ /^[\d\.]+$/)
      puts "#{name} - #{tuple}"
      light = tuple[2].to_i
      unless lasts[name] and lasts[name][:value]
        lasts[name][:value] = light
        next
      end
      msg = nil
      stat = nil
      if threshold < light-lasts[name][:value]
        msg = "#{name}で電気が点きました"
        stat = :on
      elsif lasts[name][:value] - light < threshold
        msg = "#{name}で電気が消えました"
        stat = :off
      end
      if [:on, :off].include? stat
        if lasts[name][:stat] != stat or
            lasts[name][:notify_at]+5 < Time.now
          puts msg
          tss.each do |name_, ts_|
            ts_.write ["skype", "send", "#{msg} - #{tuple}"]
            ts_.write ["twitter", "tweet", "#{msg} - #{tuple}"]
            ts_.write ["say", msg] if name_ != name
            ts_.write ["sensor", "light", stat] if name_ == name
          end
        end
        lasts[name] = {:stat => stat, :notify_at => Time.now}
      end
      lasts[name][:value] = light
    }
  end
end

linda.io.on :disconnect do
  puts "RocketIO disconnected.."
end

linda.wait

#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/rocketio/linda/client'
$stdout.sync = true

url =   ENV["LINDA_BASE"] || ARGV.shift || "http://localhost:5000"
spaces = (ENV["LINDA_SPACES"]||ENV["LINDA_SPACE"]||"test").split(/,/)
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
    ts.watch ["sensor", "light"] do |tuple|
      next unless tuple.size == 3 and (tuple[2].to_s =~ /^[\d\.]+$/)
      puts "#{name} - #{tuple}"
      light = tuple[2].to_i
      if lasts[name] and lasts[name][:value]
        light_d = light - lasts[name][:value]
        msg = nil
        stat = nil
        if light_d > 20
          msg = "#{name}で電気が点きました"
          stat = "on"
        elsif light_d < -20
          msg = "#{name}で電気が消えました"
          stat = "off"
        end
        if msg
          puts msg
          if !lasts[name][:notify] or
              lasts[name][:notify] < (Time.now-5) or
              (lasts[name][:stat] and lasts[name][:stat] != stat)
            tss.values.each do |ts_|
              ts_.write ["skype", "send", "#{msg} - #{tuple}"]
              ts_.write ["twitter", "tweet", "#{msg} - #{tuple}"]
            end
            tss.each do |name_, ts_|
              next if name_ == name
              ts_.write ["say", msg]
            end
          end
          lasts[name][:stat] = stat
          lasts[name][:notify] = Time.now
        end
      end
      lasts[name][:value] = light
    end
  end
end

linda.io.on :disconnect do
  puts "RocketIO disconnected.."
end

linda.wait

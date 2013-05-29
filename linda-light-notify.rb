#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/rocketio/linda/client'
$stdout.sync = true

url =   ENV["LINDA_BASE"]  || ARGV.shift || "http://localhost:5000"
spaces = (ENV["LINDA_SPACES"] || "test").split(/,/)
puts "connecting.. #{url}"
linda = Sinatra::RocketIO::Linda::Client.new url

tss = {}
spaces.each do |i|
  tss[i] = linda.tuplespace[i]
end

lasts = {}

linda.io.on :connect do  ## RocketIO's "connect" event
  puts "connect!! <#{linda.io.session}> (#{linda.io.type})"
  tss.each do |name, ts|
    ts.watch ["sensor", "light"] do |tuple|
      next unless tuple.size == 3 and tuple[2] =~ /^[\d\.]+$/
      puts "#{name} - #{tuple}"
      light = tuple[2].to_i
      if lasts[name]
        light_d = light - lasts[name]
        puts light_d
        msg = nil
        if light_d > 20
          msg = "#{name}で電気が点きました"
        elsif light_d < -20
          msg = "#{name}で電気が消えました"
        end
        if msg
          puts msg
          tss.values.each do |ts_|
            ts_.write ["skype", "send", msg]
          end
          tss.each do |name_, ts_|
            next if name_ == name
            ts_.write ["say", msg]
          end
        end
      end
      lasts[name] = light
    end
  end
end

linda.io.on :disconnect do
  puts "RocketIO disconnected.."
end

linda.wait

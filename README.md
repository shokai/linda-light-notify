Linda Light Notify
==================
notify Light sensor value from Arduino to skype and say-command with RocketIO::Linda

- https://github.com/shokai/linda-light-notify
- watch Tuples ["sensor", "light", Number] and detect status.
- write Tuples
  - ["sensor", "light", "on"] or ["sensor", "light", "off"]
  - ["say", "#{name}で電気が点きました"]
  - ["skype", "send", "#{name}で電気が点きました"]
  - ["twitter", "tweet", "#{name}で電気が点きました"]

Dependencies
------------
- Ruby 1.8.7 ~ 2.0.0
- [linda-arduino-sensor](https://github.com/shokai/linda-arduino-sensor)
- [linda-mac-say](https://github.com/shokai/linda-mac-say)
- [linda-skype](https://github.com/shokai/linda-skype)
- [linda-twitter](https://github.com/shokai/linda-twitter)
- [LindaBase](https://github.com/shokai/linda-base)


Install Dependencies
--------------------

    % gem install bundler foreman
    % bundle install


Run
---

set ENV var "LINDA_BASE", "LINDA_SPACES" "LIGHT_THRESHOLD"

    % export LINDA_BASE=http://linda.example.com
    % export LINDA_SPACES="shokai_room,my_room,my_room2"  ## separate with comma
    % export LIGHT_THRESHOLD=30
    % bundle exec ruby linda-light-notify.rb

or

    % LINDA_BASE=http://linda.example.com LINDA_SPACES="shokai_room,my_room,my_room2" LIGHT_THRESHOLD=30 bundle exec ruby linda-light-notify.rb


Install as Service
------------------

for launchd (Mac OSX)

    % sudo foreman export launchd /Library/LaunchDaemons/ --app linda-light-notify -u `whoami`
    % sudo launchctl load -w /Library/LaunchDaemons/linda-light-notify-notify-1.plist

for upstart (Ubuntu)

    % sudo foreman export upstart /etc/init/ --app linda-light-notify -d `pwd` -u `whoami`
    % sudo service linda-light-notify start

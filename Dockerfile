FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A69BAFCB966EF2D2
RUN echo "deb http://ppa.launchpad.net/sonic-pi/ppa/ubuntu xenial main" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y install sonic-pi netcat

ENV LANG en_GB.UTF-8

# RUN mv /etc/security/limits.d/audio.conf.disabled /etc/security/limits.d/audio.conf
# TODO figure out how to get jackd2 working
# RUN dpkg-reconfigure -p high jackd2
# jackd2 throws errors about memory access so use jackd1 instead
RUN apt-get -y install jackd1

RUN gem install sonic-pi-cli

# swallow the GUI messages
RUN nc -u 127.0.0.1 4558 &

# boot jack with dummy backend
RUN jackd -r -t 100000  -d dummy -r 44100 &

RUN /usr/lib/sonic-pi/server/bin/sonic-pi-server.rb

# RUN sonic_pi "recording_start; sleep 1; play 60; sleep 2; recording_stop; sleep 1; recording_save('/tmp/foo.wav'); sleep 2"

#CMD ["/bin/bash", "-l", "-c", "/usr/src/app/app/server/bin/sonic-pi-server.rb"]
# TCP not working for some reason
# CMD ["/bin/bash", "-l", "-c", "/usr/src/app/app/server/bin/sonic-pi-server.rb -t"]

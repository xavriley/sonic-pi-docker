FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A69BAFCB966EF2D2
RUN echo "deb http://ppa.launchpad.net/sonic-pi/ppa/ubuntu xenial main" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y install sonic-pi netcat sudo

ENV LANG en_GB.UTF-8

# RUN mv /etc/security/limits.d/audio.conf.disabled /etc/security/limits.d/audio.conf
# TODO figure out how to get jackd2 working
# RUN dpkg-reconfigure -p high jackd2
# jackd2 throws errors about memory access so use jackd1 instead
# source http://stackoverflow.com/a/37980481
RUN apt-get -y install jackd1

RUN echo "@audio          -       rtprio          99" >> /etc/security/limits.conf
RUN dpkg-reconfigure -p high jackd

RUN export uid=1000 gid=1000 && \
		mkdir -p /home/developer && \
		echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
		echo "developer:x:${uid}:" >> /etc/group && \
		echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
		chmod 0440 /etc/sudoers.d/developer && \
		chown ${uid}:${gid} -R /home/developer

RUN echo 'developer:sonicpi' | chpasswd

RUN sudo usermod -aG audio developer
RUN echo "GEM_HOME=$HOME/.gem" >> /home/developer/.bash_profile
RUN echo "PATH=$PATH:$HOME/.gem/bin" >> /home/developer/.bash_profile
RUN chmod 755 /home/developer

USER developer

WORKDIR /home/developer
ADD Gemfile .
ADD server.rb .

RUN /bin/bash -c "source ~/.bash_profile && sudo gem install bundler"

RUN /bin/bash -c "cd /home/developer && bundle install --gemfile=./Gemfile"

EXPOSE 4567

# swallow the GUI messages
# boot jack with dummy backend
# boot sonic pi server
# boot web server
CMD ["/bin/bash", "-c", "(nc -u 127.0.0.1 4558 &) && (jackd -r -t 100000  -d dummy -r 44100 &) && (/usr/lib/sonic-pi/server/bin/sonic-pi-server.rb &) && ruby server.rb -p $PORT -o 0.0.0.0"]

#CMD ["/usr/bin/bash", "-c", "/usr/bin/ruby", "./server.rb"]

# RUN sonic_pi "recording_start; sleep 1; play 60; sleep 2; recording_stop; sleep 1; recording_save('/tmp/foo.wav'); sleep 2"

#CMD ["/bin/bash", "-l", "-c", "/usr/src/app/app/server/bin/sonic-pi-server.rb"]
# TCP not working for some reason
# CMD ["/bin/bash", "-l", "-c", "/usr/src/app/app/server/bin/sonic-pi-server.rb -t"]

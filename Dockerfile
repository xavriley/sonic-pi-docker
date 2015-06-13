FROM ruby:2.1

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install \
    git-core \
    sudo \
    supercollider-server \
    libqt5scintilla2-dev \
    libqt5scintilla2-l10n \
    qt5-qmake \
    qtbase5-dev \
    cmake \
    pkg-config \
    libffi-dev \
    dbus-x11 \
    vim
    #x11vnc xvfb \
    #openssh-server

# RUN mv /etc/security/limits.d/audio.conf.disabled /etc/security/limits.d/audio.conf
# TODO figure out how to get jackd2 working
RUN dpkg-reconfigure -p high jackd2

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

RUN sudo usermod -aG audio developer

# app is a significant folder for the Ruby baseimage
RUN cd /usr/src && git clone https://github.com/samaaron/sonic-pi.git app
RUN chown -R developer /usr/src/app

USER developer
ENV HOME /home/developer

# RUN mkdir ~/.vnc
# # Setup a password
# RUN x11vnc -storepasswd 1234 ~/.vnc/passwd
# RUN x11vnc -nopw -create -forever &

WORKDIR /usr/src/app

RUN sed -i -e 's/^.*Qt4Qt5 -lqscintilla2$/ LIBS += -L\/usr\/lib -lqscintilla2/' /usr/src/app/app/gui/qt/SonicPi.pro
RUN sed -i -e 's/^ INCLUDEPATH.*/ INCLUDEPATH += -L\/usr\/lib/' /usr/src/app/app/gui/qt/SonicPi.pro
RUN sed -i -e 's/^ DEPENDPATH.*/ DEPENDPATH += -L\/usr\/lib/' /usr/src/app/app/gui/qt/SonicPi.pro

# RUN sed -i -e 's/localhost/127.0.0.1/' /usr/src/app/app/server/core.rb
# RUN sed -i -e 's/localhost/127.0.0.1/' /usr/src/app/app/server/bin/sonic-pi-server.rb

RUN ./app/server/bin/compile-extensions.rb
# RUN ./app/gui/qt/rp-build-app

RUN echo "/usr/bin/jackd -m -dalsa -r44100 -p4096 -n3 -s -D -Chw:I82801AAICH -Phw:I82801AAICH" > ~/.jackdrc && chmod 755 ~/.jackdrc

RUN sudo gem install sonic-pi-cli

RUN echo "eval \`dbus-launch --auto-syntax 2>&1\`" > ~/.bash_profile

CMD ["/bin/bash", "-l", "-c", "/usr/src/app/app/server/bin/sonic-pi-server.rb"]
# TCP not working for some reason
# CMD ["/bin/bash", "-l", "-c", "/usr/src/app/app/server/bin/sonic-pi-server.rb -t"]

# At some point we might be able to get X11 forwarding working
# to run the QT app inside Docker as well
# CMD ["/bin/bash", "-i", "-l", "-c", "/usr/src/app/app/gui/qt/rp-app-bin"]

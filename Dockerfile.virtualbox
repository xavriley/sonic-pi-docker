FROM ruby:2.1

RUN echo "deb http://http.debian.net/debian jessie main" >> /etc/apt/sources.list

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install \
    git-core \
    sudo \
    fftw3-dev \
    supercollider-server \
    supercollider-dev \
    libqt5scintilla2-dev \
    libqt5scintilla2-l10n \
    qt5-qmake \
    qtbase5-dev \
    qttools5-dev-tools \
    cmake \
    pkg-config \
    libffi-dev \
    dbus-x11 \
    vim \
    libdbus-glib-1-2 \
    libgtk2.0-0 \
    libxrender1 \
    libxt6 \
    xz-utils \
    xauth \
    openssh-server pwgen \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && \
    sed -i "s/PermitRootLogin without-password/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    echo "X11Forwarding yes" >> /etc/ssh/sshd_config && \
    echo "X11UseLocalhost no" >> /etc/ssh/sshd_config

ENV LANG en_GB.UTF-8

# RUN mv /etc/security/limits.d/audio.conf.disabled /etc/security/limits.d/audio.conf
# TODO figure out how to get jackd2 working
# RUN dpkg-reconfigure -p high jackd2

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

RUN echo 'developer:sonicpi' | chpasswd

RUN sudo usermod -aG audio developer

# Build the SuperCollider Extra UGens
RUN cd /usr/src && git clone git://github.com/supercollider/sc3-plugins.git && \
    cd sc3-plugins && git submodule init && git submodule update && \
    mkdir build && cd build && \
    cmake -DSC_PATH=/usr/include/SuperCollider -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release .. && \
    make && make install && ldconfig

# app is a significant folder for the Ruby baseimage
RUN cd /usr/src && git clone https://github.com/samaaron/sonic-pi.git app
RUN chown -R developer /usr/src/app

USER developer
ENV HOME /home/developer
ENV QT_SELECT qt5

# RUN mkdir ~/.vnc
# # Setup a password
# RUN x11vnc -storepasswd 1234 ~/.vnc/passwd
# RUN x11vnc -nopw -create -forever &

WORKDIR /usr/src/app

RUN sed -i -e 's/^.*Qt4Qt5 -lqscintilla2$/ LIBS += -L\/usr\/lib -lqt5scintilla2/' /usr/src/app/app/gui/qt/SonicPi.pro
RUN sed -i -e 's/^.*+= -lqscintilla2$//' /usr/src/app/app/gui/qt/SonicPi.pro
RUN sed -i -e 's/^ INCLUDEPATH.*/ INCLUDEPATH += -L\/usr\/lib/' /usr/src/app/app/gui/qt/SonicPi.pro
RUN sed -i -e 's/^ DEPENDPATH.*/ DEPENDPATH += -L\/usr\/lib/' /usr/src/app/app/gui/qt/SonicPi.pro

# RUN sed -i -e 's/localhost/127.0.0.1/' /usr/src/app/app/server/core.rb
# RUN sed -i -e 's/localhost/127.0.0.1/' /usr/src/app/app/server/bin/sonic-pi-server.rb

RUN ./app/server/bin/compile-extensions.rb
RUN ./app/gui/qt/rp-build-app

RUN echo "/usr/bin/jackd -m -dalsa -r44100 -p4096 -n3 -s -D -Chw:I82801AAICH -Phw:I82801AAICH" > ~/.jackdrc && chmod 755 ~/.jackdrc

RUN sudo gem install sonic-pi-cli

RUN echo "eval \`dbus-launch --auto-syntax 2>&1\`" > ~/.bash_profile

EXPOSE 22

# CMD ["/bin/bash", "-l", "-c", "/usr/src/app/app/server/bin/sonic-pi-server.rb"]
# TCP not working for some reason
# CMD ["/bin/bash", "-l", "-c", "/usr/src/app/app/server/bin/sonic-pi-server.rb -t"]

# At some point we might be able to get X11 forwarding working
# to run the QT app inside Docker as well
#CMD ["/bin/bash", "-i", "-l", "-c", "/usr/src/app/app/gui/qt/rp-app-bin"]

# Must be run as root for sshd to work
RUN sudo /usr/bin/ssh-keygen -A
CMD sudo /usr/sbin/sshd -D

# Running Sonic Pi in Docker

_warning_: this is a lot less fun than you'd think...
Probably only of interest to Sonic Pi developers or anyone looking to
Dockerize similar audio applications that used `jackd`.

## Getting Started (OS X)

This uses Vagrant and VirtualBox so you'll need plenty of spare RAM and disk space.

```
# (cd into this dir)

brew tap caskroom/cask
brew cask install virtualbox
brew cask install vagrant
vagrant plugin install vagrant-docker-exec
vagrant up
```

The first time this will take something like 30 minutes as its
building a docker host with 40Gb of disk and 2Gb of RAM, and then
proceeding to build the docker container for Sonic Pi

When that's up you'll be rewarded with a beep

```
vagrant docker-exec -- sonic_pi "play 70"
```

## Rationale

I'm looking to get Docker working so that we can have a way to run sandboxed
Sonic Pi code on a server for recording Gists in a sandbox and the like. It would also help
in some development situations, mainly to test against a similar distro to Raspbian
but on a faster machine than the RPi.

## `boot2docker` won't work for this

OSX and windows users can't use Docker directly. They need to run a virtual copy of
linux \(a 'host' in docker terms\) which then allows you to run the Docker containers
inside that. The popular solution for this is called `boot2docker` and it's the one
all the tutorials will point you to if you have a Mac or Windows machine.

The problem is that `boot2docker` runs a version of Linux that doesn't have any sound
drivers installed \(It's a custom build of Tiny Core Linux for anyone who's curious...\)

> "No problem, I'll just `boot2docker ssh` and install the sound drivers using the package manager!"

Erm, yeah about that... This version of Tiny Core Linux renames the
kernel when building to `boot2docker-4.0.4` or similar. The package
manager in Tiny Core Linux happens to use the kernel name to figure out
which packages to install - whether they need 32 or 64 bit - and the
main repo has no idea that boot2docker exists. That means you can't
actually use the package manager for many things with `boot2docker`. On
top of that, any changes you made would get nuked on upgrade. That means
`boot2docker` is a no-go until I can figure out how to do a build with
sound support \(which I've started on
[here](https://github.com/xavriley/boot2docker)\)

## Setting up a Docker host in VirtualBox with sound

If you already run Linux you can skip all this...

I opted to install a fresh copy of Debian Jessie into a VirtualBox image
with 2Gb of memory and 8Gb of storage. The audio for this VM *must* be
set to

```
Host Driver: CoreAudio
Controller:  ICH AC97
```

Once you have Jessie installed and running you need to:

### Install SuperCollider

This step probably isn't necessary but it's a good way of exercising all
the audio setup of the VM.

```
$ sudo apt-get install supercollider

$ sudo usermod -aG audio <yourusername>

$ echo "@audio    -    rtprio    99" >> /etc/security/limits.conf
$ echo "@audio    -    memlock    unlimited" >> /etc/security/limits.conf

$ echo "/usr/bin/jackd -v -m -dalsa -r44100 -p4096 -n3 -s -Chw:I82801AAICH -Phw:I82801AAICH" > ~/.jackdrc
```

### Disabling Pulseaudio

Pulseaudio is great but it's going to get in our way later. When we give
control of the soundcard over to Docker we need to make sure that no
other devices are using, which means disabling any audio applications
(like jackd or pulseaudio) in the host VM. The way described [here](https://wiki.archlinux.org/index.php/PulseAudio/Examples#The_old_way) is not
the only way to do this, but it is the one that I got to work.

> To use PulseAudio with JACK, JACK must be started before PulseAudio,
> using whichever method one prefers. PulseAudio then needs to be started
> loading the two relevant modules. Edit /etc/pulse/default.pa, and change
> the following region:

```
### Load audio drivers statically (it is probably better to not load
### these drivers manually, but instead use module-hal-detect --
### see below -- for doing this automatically)
#load-module module-alsa-sink
#load-module module-alsa-source device=hw:1,0
#load-module module-oss device="/dev/dsp" sink_name=output
source_name=input
#load-module module-oss-mmap device="/dev/dsp" sink_name=output
source_name=input
#load-module module-null-sink
#load-module module-pipe-sink

### Automatically load driver modules depending on the hardware
available
.ifexists module-udev-detect.so
load-module module-udev-detect
.else
### Alternatively use the static hardware detection module (for systems
that
### lack udev support)
load-module module-detect
.endif
```

> to the following:

```
### Load audio drivers statically (it is probably better to not load
### these drivers manually, but instead use module-hal-detect --
### see below -- for doing this automatically)
#load-module module-alsa-sink
#load-module module-alsa-source device=hw:1,0
#load-module module-oss device="/dev/dsp" sink_name=output
source_name=input
#load-module module-oss-mmap device="/dev/dsp" sink_name=output
source_name=input
#load-module module-null-sink
#load-module module-pipe-sink
load-module module-jack-source
load-module module-jack-sink

### Automatically load driver modules depending on the hardware
available
#.ifexists module-udev-detect.so
#load-module module-udev-detect
#.else
### Alternatively use the static hardware detection module (for systems
that
### lack udev support)
#load-module module-detect
#.endif
```

> Basically, this prevents module-udev-detect from loading.
> module-udev-detect will always try to grab the sound card (JACK has
> already done that, so this will cause an error). Also, the JACK source
> and sink must be explicitly loaded.


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

For something slightly more fun try

```
vagrant docker-exec -- sonic_pi "$(wget -O - https://gist.githubusercontent.com/xavriley/ab0e7ad9b956c18af9f9/raw/68157657a9324e37fa8868a6137af6ace6952e30/wxg_piece.rb)"
# Listen to the output for a while
vagrant docker-exec -- sonic_pi "stop"
```

NB with that last command it's actually the OSX host that's downloading the gist,
not the Docker container which is just being fed a string.

## Rationale

I'm looking to get Docker working so that we can have a way to run sandboxed
Sonic Pi code on a server for recording Gists in a sandbox and the like. It would also help
in some development situations, mainly to test against a similar distro to Raspbian
but on a faster machine than the RPi.

## Goals

- [x] Make beeps using sonic\_pi gem
- [ ] Run sshd server
- [ ] Run the GUI via X11 and ssh forwarding
- [ ] Remove the `--privileged` flag so code is truly sandboxed

## Related blog posts

I had to do a lot of research just to figure out how to get Linux audio
to work in VirtualBox in the way I wanted. In that sense I think this repo
has made some progress in that area and I can see useful approaches in here for
other libraries that used `jackd` like SuperCollider or Overtone. With that in mind,
heres a "reading list" of useful resources in Dockerizing audio applications in general.

- [Running GUI apps with Docker](http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/)
- [Docker containers on the Desktop](https://blog.jessfraz.com/post/docker-containers-on-the-desktop/)
- [Docker Desktop](https://github.com/rogaha/docker-desktop)
- [Running an SSH service on Docker](https://docs.docker.com/examples/running_ssh_service/)
- [SuperCollider and jackd the easy way](http://carlocapocasa.com/supercollider-jack-the-easy-way/)
- [Top 5 wrong ways to fix your (Linux) audio](http://voices.canonical.com/david.henningsson/2012/07/13/top-five-wrong-ways-to-fix-your-audio/)

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

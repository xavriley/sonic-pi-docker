ENV['VAGRANT_DEFAULT_PROVIDER'] = 'docker'
DOCKER_HOST_NAME = "dockerhost"
DOCKER_HOST_VAGRANTFILE = "./DockerHostVagrantfile"

Vagrant.configure("2") do |config|

  config.vm.define "sonicpi" do |a|
    a.vm.provider "docker" do |d|
      #d.ports = ["4557:4557/udp", "5900:5900"]
      d.build_dir = "."
      d.build_args = ["-t=sonic-pi"]
      d.remains_running = true
      # Port forwarding tcp was not working out
      #d.create_args = ["-p", "4557:4557/tcp", "-p", "5900:5900", "--privileged", "-v", "/dev/snd:/dev/snd:rw"]
      d.create_args = ["-p", "5900:5900", "--privileged", "-v", "/dev/snd:/dev/snd:rw"]
      d.volumes = ["/Users/xavierriley/Projects/sonic-pi:/usr/local/src"]
      d.vagrant_machine = "#{DOCKER_HOST_NAME}"
      d.vagrant_vagrantfile = "#{DOCKER_HOST_VAGRANTFILE}"
    end
  end

end

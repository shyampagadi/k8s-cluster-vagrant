# Vagrantfile - single-file multi-node cluster (1 master + 3 workers)
# Expects scripts/bootstrap.sh to exist in ./scripts/bootstrap.sh
Vagrant.configure("2") do |config|
  BOX = "ubuntu/focal64"
  MASTER_IP = "192.168.56.10"
  WORKER_COUNT = 3
  BASE_NET = "192.168.56."

  config.vm.box = BOX

  # Master machine
  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: MASTER_IP

    # Upload bootstrap and run it (use file in ./scripts/bootstrap.sh)
    master.vm.provision "file", source: "scripts/bootstrap.sh", destination: "/vagrant/bootstrap.sh"
    master.vm.provision "shell", inline: "sudo bash /vagrant/bootstrap.sh master #{MASTER_IP} #{WORKER_COUNT}", privileged: true
  end

  # Worker machines
  (1..WORKER_COUNT).each do |i|
    ip = "192.168.56.#{10 + i}"
    config.vm.define "worker#{i}" do |worker|
      worker.vm.hostname = "worker#{i}"
      worker.vm.network "private_network", ip: ip

      # Upload same bootstrap and run as worker
      worker.vm.provision "file", source: "scripts/bootstrap.sh", destination: "/vagrant/bootstrap.sh"
      worker.vm.provision "shell", inline: "sudo bash /vagrant/bootstrap.sh worker #{MASTER_IP} #{WORKER_COUNT}", privileged: true
    end
  end

  # Provider tuning (optional)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
    # Ensure proper networking
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
  end
end

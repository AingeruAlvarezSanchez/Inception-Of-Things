# frozen_string_literal: true

class VagrantClusterConfigurator
  @path = nil
  @inventory = nil
  @playbook = nil
  @nodes = []
  @box = 'generic/alpine319'
  public def initialize(path, inventory = nil, playbook = nil)
    read_file(path)
    vagrantfile
  end

  private def vagrantfile
    Vagrant.configure('2') do |config|
      config.vm.box = @box
      config.vm.box_check_update = true 

      raise 'No nodes defined' if @nodes.empty?
      @nodes.each do |node|
          provision_node(config, node)
       end
    end
  end

  private def provision_node(config, node)
    config.vm.define node[:name] do |machine|
      machine.vm.hostname = node[:hostname]
      machine.vm.network 'private_network', ip: node[:network_address]

      provision_libvirt(machine, node)
      provision_ansible(machine)
    end
  end

  private  def read_file(path)
    raise "File not found: #{path}" unless File.exist?(path)
    @path = File.expand_path(path)
    @nodes = JSON.parse(
      File.read(path),
      symbolize_names: true
    )
    raise 'No nodes defined' if @nodes.empty?
  end

  private def provision_ansible(machine, script = nil, inventory = nil, playbook = nil)
    machine.vm.provision 'shell', path: 'scripts/bootstrap.sh'
    machine.vm.provision 'ansible' do |ansible|
      ansible.inventory_path = 'scripts/ansible/inventory.ini'
      ansible.playbook = 'scripts/ansible/playbook.yml'
      ansible.verbose = 'vvv'
    end
  end

  private def assert(condition, message)
    raise message unless condition
  end
  private def provision_libvirt(machine, node)
    machine.vm.provider :libvirt do |lv|
      lv.default_prefix = ''
      lv.memory = node[:memory]
      lv.cpus = node[:cpus]
    end
  end
end

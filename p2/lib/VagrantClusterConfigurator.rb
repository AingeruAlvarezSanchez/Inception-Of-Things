# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'Utils'

class VagrantClusterConfigurator < Utils
  DEFAULT_VERBOSE   = '--verbose'
  DEFAULT_PATH      = 'confs/config.json'
  DEFAULT_SCRIPT    = 'scripts/bootstrap.sh'
  DEFAULT_PLAYBOOK  = 'scripts/ansible/playbook.yml'
  DEFAULT_INVENTORY = 'scripts/ansible/inventory.ini'
  attr_reader :nodes, :path, :script, :verbose, :playbook, :inventory 

  def initialize(path: DEFAULT_PATH, inventory: DEFAULT_INVENTORY, playbook: DEFAULT_PLAYBOOK, script: DEFAULT_SCRIPT, verbose: DEFAULT_VERBOSE)
    @nodes     = []
    @path      = path
    @script    = script
    @verbose   = verbose 
    @playbook  = playbook
    @inventory = inventory

    Utils.validate_conf_vagrant(@path, @inventory, @playbook, @script)
    @nodes = Utils.read_file(@path)
    generate
  end

  private

  private def generate
    raise 'No nodes defined' if @nodes.empty?

    Vagrant.configure('2') do |config|
      config.vm.box_check_update = true

      @nodes.each do |node|
        config.vm.box =  node[:box] || 'generic/alpine319'
        provision_node(config, node)
      end
    end
  end

  private  def provision_node(config, node)
    config.vm.define node[:name] do |machine|
      machine.vm.hostname = node[:hostname]
      machine.vm.network 'private_network', ip: node[:network_address]
      # machine.vm.network :public_network,
      #   ip: node[:network_address],
      #   mac: node[:mac_address],
      #   bridge: "br0",
      #   dev: "br0",
      #   mode: "bridge",
      #   type: "bridge",
      #   libvirt__network_name: "br0",
      #   libvirt__forward_mode: "bridge"
 
      machine.vm.synced_folder 'scripts', '/vagrant/scripts',
      #type: 'rsync',
      provision_libvirt(machine, node)
      provision_ansible(machine)
    end
  end

  private  def provision_ansible(machine, privileged: true)
    machine.vm.provision 'shell', path: @script, privileged: privileged if @script
    machine.vm.provision 'ansible' do |ansible|
      ansible.inventory_path = @inventory
      ansible.playbook = @playbook
      ansible.verbose = @verbose
      ansible.become = true if privileged
    end
  end

  private  def provision_libvirt(machine, node)
    machine.vm.provider :libvirt do |lv|
      lv.default_prefix = ''
      lv.memory = node[:memory]
      lv.cpus = node[:cpus]
    end
  end
end


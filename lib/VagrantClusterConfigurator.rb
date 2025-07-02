# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'Utils'

class VagrantClusterConfigurator
  DEFAULT_VERBOSE   = '--verbose'
  DEFAULT_PATH      = 'confs/config.json'
  DEFAULT_SCRIPT    = 'scripts/bootstrap.sh'
  DEFAULT_CFG       = "scripts/ansible.cfg"
  DEFAULT_PLAYBOOK  = 'scripts/ansible/playbook/site.yml'
  DEFAULT_INVENTORY = 'scripts/ansible/inventory/dev/inventory.ini'
  attr_reader :nodes, :path, :script, :verbose, :playbook, :inventory, :cfg

  def initialize(path: DEFAULT_PATH, inventory: DEFAULT_INVENTORY, playbook: DEFAULT_PLAYBOOK, script: DEFAULT_SCRIPT, verbose: DEFAULT_VERBOSE, cfg: DEFAULT_CFG)
    @nodes     = []
    @path      = path
    @script    = script
    @verbose   = verbose 
    @playbook  = playbook
    @inventory = inventory
    @cfg       = cfg

    Utils.validate_conf_vagrant(@path, @inventory, @playbook, @script, @cfg)
    @nodes = Utils.read_file(@path)
    generate
  end

  private def generate
    raise 'No nodes defined' if @nodes.empty?

    Vagrant.configure('2') do |config|
      config.vm.box_check_update = true

      @nodes.each do |node|
        config.vm.box =  node[:box] || 'cloud-image/debian-12'
        provision_node(config, node)
      end
    end
  end

  private def provision_node(config, node)
    config.vm.define node[:name] do |machine|
      machine.vm.hostname = node[:hostname]
      machine.vm.network 'private_network', ip: node[:network_address]
 
      machine.vm.synced_folder 'scripts', '/inception/scripts',
        type: 'rsync',
        rsync__auto: true,      
        rsync__exclude: '.git/'  

      provision_libvirt(machine, node)
      provision_ansible(machine)
    end
  end

  private def provision_ansible(machine, privileged: true)
    machine.vm.provision 'shell', path: @script, privileged: privileged if @script
    machine.vm.provision 'ansible' do |ansible|
      ansible.config_file    = @cfg
      ansible.verbose        = @verbose
      ansible.playbook       = @playbook
      ansible.inventory_path = @inventory
      ansible.become         = true if privileged
    end
  end

  private def provision_libvirt(machine, node)
    machine.vm.provider :libvirt do |lv|
      lv.cpus = node[:cpus]
      lv.default_prefix = ''
      lv.memory = node[:memory]
    end
  end
end


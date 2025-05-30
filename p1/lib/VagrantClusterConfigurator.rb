

# frozen_string_literal: true

require 'json'

class VagrantClusterConfigurator
  DEFAULT_BOX       = 'generic/alpine319'
  DEFAULT_INVENTORY = 'scripts/ansible/inventory.ini'
  DEFAULT_PLAYBOOK  = 'scripts/ansible/playbook.yml'
  DEFAULT_SCRIPT    = 'scripts/bootstrap.sh'
  DEFAULT_PATH      = 'confs/config.json'
  DEFAULT_VERBOSE   = 'vvv'
  attr_reader :nodes
  

  def initialize(path: DEFAULT_PATH, box: DEFAULT_BOX, inventory: DEFAULT_INVENTORY, playbook: DEFAULT_PLAYBOOK, script: DEFAULT_SCRIPT, verbose: DEFAULT_VERBOSE)
    @path      = path
    @box       = box
    @inventory = inventory
    @playbook  = playbook
    @script    = script
    @nodes     = []
    @box       = box
    @verbose   = verbose 

    validate_configuration
    read_file
    generate
  end

  private

  private def validate_configuration
    validate_file(@path, '.json', 'Path must be a valid JSON file')
    validate_file(@inventory, '.ini', 'Inventory must be an INI file')
    validate_file(@playbook, '.yml', 'Playbook must be a YAML file')
    raise 'Box name cannot be nil or empty' if @box.to_s.strip.empty?
  end

  private  def validate_file(path, ext, msg)
    raise "#{msg}: path is nil or empty" if path.nil? || path.strip.empty?
    raise "#{msg}: file does not exist: #{path}" unless File.exist?(path)
    raise "#{msg}: invalid extension: #{path}" unless File.extname(path) == ext
  end

  private def read_file()
    @nodes = JSON.parse(File.read(@path), symbolize_names: true)
    raise 'No nodes defined in JSON' if @nodes.empty?
  end

  private def generate
    raise 'No nodes defined' if @nodes.empty?

    Vagrant.configure('2') do |config|
      config.vm.box = @box
      config.vm.box_check_update = true

      @nodes.each do |node|
        provision_node(config, node)
      end
    end
  end

  private  def provision_node(config, node)
    config.vm.define node[:name] do |machine|
      machine.vm.hostname = node[:hostname]
      machine.vm.network 'private_network', ip: node[:network_address]
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


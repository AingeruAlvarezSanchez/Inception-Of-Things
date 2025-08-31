
# frozen_string_literal: true
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'


class Utils
  def self.validate_conf_vagrant(*args)
    expected = ['.json', '.ini', '.yml', '.sh', '.cfg']
    messages = [
      'Path must be a valid JSON file',
      'Inventory must be an INI file',
      'Playbook must be a YAML file',
      'Script must be a SH file',
      'Ansible Config must be cfg file'
    ]

    args.each_with_index do |path, i|
      validate_file(path, expected[i], messages[i])
    end
  end

  def self.read_file(path)
    raise 'Path to JSON is nil or empty' if path.nil? || path.strip.empty?
    raise "File does not exist: #{path}" unless File.exist?(path)

    nodes = JSON.parse(File.read(path), symbolize_names: true)
    raise 'No nodes defined in JSON' if nodes.empty?

    nodes # retornamos el array de nodos
  end
  
  def self.validate_file(path, ext, msg)
    raise "#{msg}: path is nil or empty" if path.nil? || path.strip.empty?
    raise "#{msg}: file does not exist: #{path}" unless File.exist?(path)
    raise "#{msg}: invalid extension: #{path}" unless File.extname(path) == ext
  end
end


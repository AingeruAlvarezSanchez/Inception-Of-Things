# -*- mode: ruby -*-
# vi: set ft=ruby :
# class Config
#   def initialize; end
#   en
def nodes
  [
    {
      nombre: 'dugonzal',
      network_address: '192.168.56.111',
      memory: 2048,
      cpu: 4
    },
    {
      nombre: 'aalvarez',
      network_address: '192.168.56.112',
      memory: 1024,
      cpu: 2
    }
  ]
end

puts nodes

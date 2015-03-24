# Set up a Consul Server node.
class socorro::role::consul {

  service {
    'consul':
      ensure    => running,
      enable    => true,
      subscribe => File[
        '/etc/consul/config.json',
        '/etc/consul/ui.json'
      ]
  }

  package {
    [
      'bind-utils',
      'consul-ui'
    ]:
    ensure => latest
  }

  file {
    '/etc/consul/server.json':
      source => 'puppet:///modules/socorro/etc_consul/server.json',
      owner  => 'root',
      group  => 'consul',
      mode   => '0640';

    '/etc/consul/ui.json':
      source  => 'puppet:///modules/socorro/etc_consul/ui.json',
      owner   => 'root',
      group   => 'consul',
      mode    => '0640',
      require => Package['consul-ui']
  }

}

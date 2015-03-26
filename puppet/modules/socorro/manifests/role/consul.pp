# Set up a Consul Server node.
class socorro::role::consul {

  service {
    'consul':
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/consul/server.json'];
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
      source  => 'puppet:///modules/socorro/etc_consul/server.json',
      owner   => 'root',
      group   => 'consul',
      mode    => '0640',
      require => Package['consul-ui'];
  }

}

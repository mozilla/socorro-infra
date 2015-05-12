# Set up a Consul Server node.
class socorro::role::consul {

include socorro::role::common

  service {
    'consul':
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/consul/server.json'];
  }

  file {
    '/etc/consul/server.json':
      source => 'puppet:///modules/socorro/etc_consul/server.json',
      owner  => 'root',
      group  => 'consul',
      mode   => '0640';
  }

}

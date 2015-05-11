# Set up an elasticsearch node.
class socorro::role::elasticsearch {

include socorro::role::common

  service {
    'elasticsearch':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }
}

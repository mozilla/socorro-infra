# Set up a postgrs node.
class socorro::role::postgres {

include socorro::role::common

  service {
    'postgresql-9.3':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }

}

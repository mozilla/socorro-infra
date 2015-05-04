# Set up a collector node.
class socorro::role::collector {

include socorro::role::common

  service {
    'nginx':
      ensure => running,
      enable => true;

    'socorro-collector':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];

    'socorro-crashmover':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }

}

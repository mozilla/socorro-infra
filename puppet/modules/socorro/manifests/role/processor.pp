# Set up a processor node.
class socorro::role::processor {

include socorro::role::common

  service {
    'socorro-processor':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }

}

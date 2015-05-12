# Set up a rabbitmq node.
class socorro::role::rabbitmq {

include socorro::role::common

  service {
    'rabbitmq-server':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }

}

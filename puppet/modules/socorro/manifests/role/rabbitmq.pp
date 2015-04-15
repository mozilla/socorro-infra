# Set up a rabbitmq node.
class socorro::role::rabbitmq {

include socorro::role::common

  service {
    'rabbitmq-server':
      ensure  => running,
      enable  => true,
      require => [
        Package['rabbitmq-server'],
        Exec['join_consul_cluster']
      ];
  }

  package {
    'rabbitmq-server':
      ensure=> latest
  }

}

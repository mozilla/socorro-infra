# Set up a rabbitmq node.
class socorro::role::rabbitmq {

  service {
    'rabbitmq-server':
      ensure  => running,
      enable  => true,
      require => Package['socorro']
  }

  package {
    'rabbitmq-server':
      ensure=> latest
  }

}

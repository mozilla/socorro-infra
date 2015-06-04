# Set up a rabbitmq node.
class socorro::role::rabbitmq {

include socorro::role::common

  service {
    'rabbitmq-server':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }

  file {
    '/etc/dd-agent/conf.d/rabbitmq.yaml':
      mode   => '0640',
      owner  => 'dd-agent',
      source => 'puppet:///modules/socorro/etc_dd-agent/rabbitmq.yaml',
  }
}

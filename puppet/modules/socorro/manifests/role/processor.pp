# Set up a processor node.
class socorro::role::processor {

include socorro::role::common

  service {
    'socorro-processor':
      ensure  => running,
      enable  => true,
      require => [
        Package['socorro'],
        Exec['join_consul_cluster']
      ];
  }

  package {
    'socorro':
      ensure=> latest;

    'nginx':
      ensure=> latest;
  }

}

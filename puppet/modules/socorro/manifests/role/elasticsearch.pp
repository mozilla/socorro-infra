# Set up an elasticsearch node.
class socorro::role::elasticsearch {

include socorro::role::common

  service {
    'elasticsearch':
      ensure  => running,
      enable  => true,
      require => [
        Package['socorro'],
        Exec['join_consul_cluster']
      ];
  }

  package {
    'elasticsearch':
      ensure=> latest;

    'socorro':
      ensure=> latest;
  }

}

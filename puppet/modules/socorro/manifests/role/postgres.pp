# Set up a postgrs node.
class socorro::role::postgres {

include socorro::role::common

  service {
    'postgresql-9.3':
      ensure  => running,
      enable  => true,
      require => [
        Package['socorro'],
        Exec['join_consul_cluster']
      ];
  }

  package {
    'postgresql93-server':
      ensure=> latest;

    'socorro':
      ensure=> latest;
  }

}

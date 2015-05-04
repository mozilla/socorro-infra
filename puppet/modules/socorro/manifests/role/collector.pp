# Set up a collector node.
class socorro::role::collector {

include socorro::role::common

  service {
    'nginx':
      ensure  => running,
      enable  => true,
      require => Package['nginx'];

    'socorro-collector':
      ensure  => running,
      enable  => true,
      require => [
        Package['socorro'],
        Exec['join_consul_cluster']
      ];

    'socorro-crashmover':
      ensure  => running,
      enable  => true,
      require => [
        Package['socorro'],
        Exec['join_consul_cluster']
      ];
  }

  package {
    'socorro':
      ensure=> installed;

    'nginx':
      ensure=> latest;
  }

}

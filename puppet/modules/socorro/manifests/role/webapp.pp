# Set up a webapp node.
class socorro::role::webapp {

include socorro::role::common

  service {
    'nginx':
      ensure  => running,
      enable  => true,
      require => Package['nginx'];

    'socorro-webapp':
      ensure  => running,
      enable  => true,
      require => [
        Package['socorro'],
        Exec['join_consul_cluster']
      ];

    'socorro-middleware':
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

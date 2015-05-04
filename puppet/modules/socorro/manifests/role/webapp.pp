# Set up a webapp node.
class socorro::role::webapp {

include socorro::role::common

  service {
    'nginx':
      ensure => running,
      enable => true;

    'socorro-webapp':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];

    'socorro-middleware':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }

}

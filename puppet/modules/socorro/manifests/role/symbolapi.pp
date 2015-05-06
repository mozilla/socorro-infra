# Set up a symbolapi node.
class socorro::role::symbolapi {

include socorro::role::common

  service {
    'mozilla-snappy':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }

}

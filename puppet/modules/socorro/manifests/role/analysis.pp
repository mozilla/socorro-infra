# Set up an analysis node.
class socorro::role::analysis {

include socorro::role::common

  service {
    'nginx':
      ensure => running,
      enable => true;
  }

}

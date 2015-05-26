# Set up a symbolapi node.
class socorro::role::symbolapi {

include socorro::role::common

  service {
    'mozilla-snappy':
      ensure => running,
      enable => true
  }

}

# Set up a symbolapi node.
class socorro::role::symbolapi {

  service {
    'mozilla-snappy':
      ensure  => running,
      enable  => true,
      require => Package['mozilla-snappy']
  }

  package {
    'mozilla-snappy':
      ensure=> latest
  }

}

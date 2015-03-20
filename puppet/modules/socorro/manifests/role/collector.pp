# Set up a collector node.
class socorro::role::collector {

  service {
    'nginx':
      ensure  => running,
      enable  => true,
      require => Package['nginx'];

    'socorro-collector':
      ensure  => running,
      enable  => true,
      require => Package['socorro'];
  }

  package {
    'socorro':
      ensure=> latest
  }

}

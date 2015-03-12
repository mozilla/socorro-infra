# Set up a collector node.
class socorro::role::collector {

  service {
    'httpd':
      ensure  => running,
      enable  => true,
      require => Package['httpd'];

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

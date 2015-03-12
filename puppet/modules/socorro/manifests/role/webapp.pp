# Set up a webapp node.
class socorro::role::webapp {

  service {
    'httpd':
      ensure  => running,
      enable  => true,
      require => Package['httpd'];

    'socorro-webapp':
      ensure  => running,
      enable  => true,
      require => Package['socorro'];
  }

  package {
    'socorro':
      ensure=> latest
  }

}

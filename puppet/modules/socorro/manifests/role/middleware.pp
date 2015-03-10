# Set up a middleware node.
class socorro::role::middleware {

  service {
    'httpd':
      ensure  => running,
      enable  => true,
      require => Package['httpd'];

    'socorro-middleware':
      ensure  => running,
      enable  => true,
      require => Package['socorro'];
  }

  package {
    'socorro':
      ensure=> latest
  }

}

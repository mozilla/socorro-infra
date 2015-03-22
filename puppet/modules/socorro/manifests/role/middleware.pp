# Set up a middleware node.
class socorro::role::middleware {

  service {
    'nginx':
      ensure  => running,
      enable  => true,
      require => Package['nginx'];

    'socorro-middleware':
      ensure  => running,
      enable  => true,
      require => Package['socorro'];
  }

  package {
    'socorro':
      ensure=> latest;

    'nginx':
      ensure=> latest;
  }

}

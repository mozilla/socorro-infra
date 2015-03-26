# Set up a webapp node.
class socorro::role::webapp {

  service {
    'nginx':
      ensure  => running,
      enable  => true,
      require => Package['nginx'];

    'socorro-webapp':
      ensure  => running,
      enable  => true,
      require => Package['socorro'];

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

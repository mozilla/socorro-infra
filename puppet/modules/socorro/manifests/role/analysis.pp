# Set up an analysis node.
class socorro::role::analysis {

  service {
    'nginx':
      ensure  => running,
      enable  => true,
      require => Package['nginx']
  }

  package {
    'nginx':
      ensure=> latest;

    'php-cli':
      ensure=> latest;
  }

}

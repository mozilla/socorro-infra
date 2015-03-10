# Set up an elasticsearch node.
class socorro::role::elasticsearch {

  service {
    'elasticsearch':
      ensure  => running,
      enable  => true,
      require => Package['socorro']
  }

  package {
    'elasticsearch':
      ensure=> latest;

    'socorro':
      ensure=> latest;
  }

}

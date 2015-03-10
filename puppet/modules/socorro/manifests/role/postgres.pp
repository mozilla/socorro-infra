# Set up a postgrs node.
class socorro::role::postgres {

  service {
    'postgresql93-server':
      ensure  => running,
      enable  => true,
      require => Package['socorro']
  }

  package {
    'postgresql93-server':
      ensure=> latest;

    'socorro':
      ensure=> latest;
  }

}

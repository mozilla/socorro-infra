# Set up a processor node.
class socorro::role::processor {

  service {
    'socorro-processor':
      ensure  => running,
      enable  => true,
      require => Package['socorro']
  }

  package {
    'socorro':
      ensure=> latest
  }

}

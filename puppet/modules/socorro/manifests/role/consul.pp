# Set up a consul node.
class socorro::role::consul {

  service {
    'consul':
      ensure  => running,
      enable  => true,
      require => File['/etc/consul.d/config.json']
  }

  package {
    [
      'bind-utils',
      'consul'
    ]:
    ensure => latest
  }

  file {
    '/etc/consul.d/config.json':
      ensure  => file,
      source  => 'puppet:///modules/socorro/etc_consul.d/config.json',
      owner   => 'root',
      group   => 'consul',
      require => Package['consul']
  }

}

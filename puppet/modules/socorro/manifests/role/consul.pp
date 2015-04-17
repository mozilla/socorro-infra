# Set up a Consul Server node.

include socorro::role::common

  service {
    'consul':
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/consul/server.json'];
  }

  package {
    [
      'bind-utils',
      'consul-ui'
    ]:
    ensure => latest
  }

  file {
    '/etc/consul/server.json':
      source  => 'puppet:///modules/socorro/etc_consul/server.json',
      owner   => 'root',
      group   => 'consul',
      mode    => '0640',
      require => Package['consul-ui'];
  }

  # We expect this to come from the secret S3 bucket
  # This is here instead of common.pp so we can depend on server.json
  $consul_hostname = hiera("${::environment}/consul_hostname")
  exec {
      'join_consul_cluster':
        command => "/usr/bin/consul join ${consul_hostname}",
        require => File['/etc/consul/server.json']
  }

}

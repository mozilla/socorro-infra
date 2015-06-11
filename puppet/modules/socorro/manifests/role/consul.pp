# Set up a Consul Server node.
class socorro::role::consul {

include socorro::role::common

  service {
    'consul':
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/consul/server.json'];
  }

  file {
    '/etc/consul/server.json':
      source => 'puppet:///modules/socorro/etc_consul/server.json',
      owner  => 'root',
      group  => 'consul',
      mode   => '0640';
  }

  # We expect this to come from the secret S3 bucket
  $consul_hostname = hiera("${::environment}/consul_hostname")
  exec {
    'join_consul_server_cluster':
      command  => "/usr/bin/consul join ${consul_hostname}",
      requires => Service['consul'];
  }

  # We want to backup consul servers every 20 min.
  file {
    '/usr/bin/backup-consul.sh':
      content => template('socorro/bin_consul/backup-consul.sh.erb'),
      owner   => 'centos',
      mode    => '0750'
  }

  $consul_environment = $::environment

  cron { 'backup-consul':
    command => '/usr/bin/backup-consul.sh 2>&1 >> /var/log/backup-consul.log',
    user    => 'centos',
    minute  => [03,23,43],
    require => File['/usr/bin/backup-consul.sh']
  }
}

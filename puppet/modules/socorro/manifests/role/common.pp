# Elements common to all Socorro roles.
class socorro::role::common {

  # We expect this to come from the secret S3 bucket
  $consul_hostname = hiera("${::environment}/consul_hostname")
  exec {
      'join_consul_cluster':
        command => "/usr/bin/consul join ${consul_hostname}"
  }

  $logging_hostname = hiera("${::environment}/logging_hostname")
  file {
    '/etc/rsyslog.d/30-socorro.conf':
      content => template('socorro/etc_rsyslog.d/30-socorro.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Service['rsyslog'];
  }

  service {
    'rsyslog':
      ensure    => running,
      enable    => true;
  }

  exec {
    'set-hostname':
      path    => '/usr/bin',
      command => '/bin/ec2-metadata -i |cut -d " " -f 2 > /etc/hostname && /bin/hostname -F /etc/hostname'
  }
}

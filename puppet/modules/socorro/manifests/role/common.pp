# Elements common to all Socorro roles.
class socorro::role::common {

  # Ensure that the hostname is the same as the EC2 instance ID.
  file {
    '/etc/hostname':
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => $::ec2_instance_id
  }

  exec {
    'set-hostname':
      path    => '/bin:/usr/bin',
      command => 'hostname -F /etc/hostname',
      require => File['/etc/hostname']
  }

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
      ensure  => running,
      enable  => true,
      require => Exec['set-hostname']
  }

}

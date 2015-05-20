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

  # Datadog agent install
  $datadog_api_key=hiera("${::environment}/datadog_api_key")

  file {
    '/etc/dd-agent/datadog.conf':
      mode    => '0640',
      owner   => dd-agent,
      content => template('socorro/etc_dd_agent/datadog.conf.erb'),
      notify  => Service['datadog-agent']
  }

  service {
    'datadog-agent':
      ensure    => running,
      enable    => true,
      hasstatus => false,
      pattern   => 'dd-agent',
      require   => File['/etc/dd-agent/datadog.conf']
  }

}

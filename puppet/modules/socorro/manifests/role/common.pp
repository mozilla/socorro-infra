# Elements common to all Socorro roles.
class socorro::role::common {

  # We expect this to come from the secret S3 bucket
  $consul_hostname = hiera("${::environment}/consul_hostname")
  exec {
    'join_consul_cluster':
      command => "/usr/bin/consul join ${consul_hostname}",
  }

  file {
    '/etc/rsyslog.d/30-socorro.conf':
      source => 'puppet:///modules/socorro/etc_rsyslog/30-socorro.conf',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      notify => Service['rsyslog'],
  }

  file {
    '/etc/dd-agent/conf.d/rabbitmq.yaml':
      mode   => '0640',
      owner  => 'dd-agent',
      source => 'puppet:///modules/socorro/etc_dd-agent/rabbitmq.yaml',
  }

  service {
    'rsyslog':
      ensure => running,
      enable => true
  }

  # Datadog agent install
  $datadog_api_key=hiera("${::environment}/datadog_api_key")

  file {
    '/etc/dd-agent/datadog.conf':
      mode    => '0640',
      owner   => 'dd-agent',
      content => template('socorro/datadog-agent/datadog.conf.erb'),
      notify  => Service['datadog-agent'],
  }

  service {
    'datadog-agent':
      ensure    => running,
      enable    => true,
      hasstatus => false,
      pattern   => 'datadog-agent',
      require   => File['/etc/dd-agent/datadog.conf']
  }
}

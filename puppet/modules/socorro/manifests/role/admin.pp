# Set up a admin node.
class socorro::role::admin {

include socorro::role::common

  file {
    '/etc/cron.d/socorro':
      mode    => '0600',
      owner   => root,
      group   => root,
      source  => 'puppet:///modules/socorro/etc_cron.d/socorro',
      require => Exec['join_consul_cluster']
  }

  file {
    '/etc/dd-agent/datadog.conf':
      mode     => '0600',
      owner    => root,
      group    => root,
      content => template('socorro/etc_dd_agent/datadog.conf.erb'),
      require  => Exec['join_consul_cluster'],
      notify   => Service['dd-agent']
  }

}

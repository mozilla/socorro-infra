# Set up a admin node.
class socorro::role::admin {

include socorro::role::common

  package {
    'socorro':
      ensure => latest
  }

  file {
    '/etc/cron.d/socorro':
      mode    => '0600',
      owner   => root,
      group   => root,
      source  => 'puppet:///modules/socorro/etc_cron.d/socorro',
      require => [
        Package['socorro'],
        Exec['join_consul_cluster']
      ]
  }

}

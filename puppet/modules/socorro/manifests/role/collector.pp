# Set up a collector node.
class socorro::role::collector {

include socorro::role::common

  service {
    'nginx':
      ensure    => running,
      enable    => true,
      require   => Package['nginx'],
      subscribe => File['/etc/nginx/conf.d/socorro-collector.conf'];

    'socorro-collector':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];

    'socorro-crashmover':
      ensure  => running,
      enable  => true,
      require => [
        Package['socorro'],
        Exec['join_consul_cluster']
      ];
  }

  file {
    '/etc/nginx/nginx.conf':
      source  => 'puppet:///modules/socorro/etc_nginx/nginx.conf',
      owner   => 'root',
      group   => 'root',
      mode    => '0664',
      require => Package['nginx'];

    '/etc/nginx/conf.d/socorro-collector.conf':
      source  => 'puppet:///modules/socorro/etc_nginx/conf_d/socorro-collector.conf',
      owner   => 'root',
      group   => 'root',
      mode    => '0664',
      require => File['/etc/nginx/nginx.conf'];
  }

  package {
    [
      'nginx',
      'socorro'
    ]:
    ensure => latest
  }

}

# Set up a webapp node.
class socorro::role::webapp {

include socorro::role::common

  $newrelic_app = hiera("${::environment}/newrelic_app")
  $newrelic_apikey = hiera("${::environment}/newrelic_apikey")

  service {
    'nginx':
      ensure    => running,
      enable    => true,
      subscribe => File[
        '/etc/nginx/conf.d/socorro-webapp.conf',
        '/etc/nginx/conf.d/socorro-middleware.conf'
      ];

    'socorro-webapp':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];

    'socorro-middleware':
      ensure  => running,
      enable  => true,
      require => [
        Exec['join_consul_cluster']
      ];
  }

  file {
    '/etc/nginx/nginx.conf':
      source => 'puppet:///modules/socorro/etc_nginx/nginx.conf',
      owner  => 'root',
      group  => 'root',
      mode   => '0664';

    '/etc/newrelic':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    '/etc/newrelic/newrelic.ini':
      owner   => 'root',
      group   => 'root',
      mode    => '0664',
      content => template('socorro/etc_newrelic/newrelic.ini.erb'),
      require => File['/etc/newrelic'];

    '/etc/nginx/conf.d/socorro-webapp.conf':
      source  => 'puppet:///modules/socorro/etc_nginx/conf_d/socorro-webapp.conf',
      owner   => 'root',
      group   => 'nginx',
      mode    => '0664',
      require => File['/etc/nginx/nginx.conf'];

    '/etc/nginx/conf.d/socorro-middleware.conf':
      source  => 'puppet:///modules/socorro/etc_nginx/conf_d/socorro-middleware.conf',
      owner   => 'root',
      group   => 'nginx',
      mode    => '0664',
      require => File['/etc/nginx/nginx.conf'];
  }

}

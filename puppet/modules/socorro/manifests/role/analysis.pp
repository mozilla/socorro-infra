# Set up an analysis node.
class socorro::role::analysis {

include socorro::role::common

  service {
    'nginx':
      ensure    => running,
      enable    => true,
      require   => Package['nginx'],
      subscribe => File['/etc/nginx/conf.d/socorro-analysis.conf'];
  }

  file {
    '/etc/nginx/nginx.conf':
      source  => 'puppet:///modules/socorro/etc_nginx/nginx.conf',
      owner   => 'root',
      group   => 'root',
      mode    => '0664',
      require => Package['nginx'];

    '/etc/nginx/conf.d/socorro-analysis.conf':
      source  => 'puppet:///modules/socorro/etc_nginx/conf_d/socorro-analysis.conf',
      owner   => 'root',
      group   => 'nginx',
      mode    => '0664',
      require => File['/etc/nginx/nginx.conf'];
  }

  package {
    [
      'php-cli',
      'nginx'
    ]:
    ensure => latest
  }

}

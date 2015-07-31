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

    '/data/bin/cron_daily_reports.sh':
      source => 'puppet:///modules/socorro/data_bin/cron_daily_reports.sh',
      owner  => 'root',
      group  => 'root',
      mode   => '0755';

    '/data/bin/cron_libraries.sh':
      source => 'puppet:///modules/socorro/data_bin/cron_libraries.sh',
      owner  => 'root',
      group  => 'root',
      mode   => '0755';

    '/data/bin/cron_missing_symbols.sh':
      source => 'puppet:///modules/socorro/data_bin/cron_missing_symbols.sh',
      owner  => 'root',
      group  => 'root',
      mode   => '0755';

    '/etc/cron.d/socorro':
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/socorro/etc_cron.d/analysis',
      require => [
        Exec['join_consul_cluster'],
        File['/data/bin/cron_daily_reports.sh'],
        File['/data/bin/cron_libraries.sh'],
        File['cron_missing_symbols.sh']
      ];
  }

  package {
    [
      'php-cli',
      'php-pgsql',
      'php-xml',
      'mercurial',
      'nano',       # really?
      'nginx'
    ]:
    ensure => latest
  }

}

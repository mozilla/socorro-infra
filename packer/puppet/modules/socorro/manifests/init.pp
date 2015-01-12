# Set up basic Socorro requirements.
class socorro::generic {

  service {
    'httpd':
      ensure  => stopped,
      enable  => false,
      require => Package['httpd'];

    'postgresql-9.3':
      ensure  => stopped,
      enable  => false,
      require => [
          Package['postgresql93-server'],
          File['pg_hba.conf'],
        ];

    'elasticsearch':
      ensure  => stopped,
      enable  => false,
      require => Package['elasticsearch'];
  }

  yumrepo {
    'elasticsearch':
      baseurl => 'http://packages.elasticsearch.org/elasticsearch/0.90/centos';
    'EPEL':
      baseurl => 'http://dl.fedoraproject.org/pub/epel/$releasever/$basearch',
      timeout => 60;
    'PGDG':
      baseurl => 'http://yum.postgresql.org/9.3/redhat/rhel-$releasever-$basearch';
  }

  Yumrepo['elasticsearch', 'EPEL', 'PGDG'] {
    enabled  => 1,
    gpgcheck => 0,
    require  => Package['yum-plugin-fastestmirror']
  }

  package {
    [
      'daemonize',
      'httpd',
      'java-1.7.0-openjdk',
      'mod_wsgi',
      'unzip',
      'yum-plugin-fastestmirror',
    ]:
    ensure => latest
  }

  package {
    [
      'postgresql93-contrib',
      'postgresql93-devel',
      'postgresql93-plperl',
      'postgresql93-server',
    ]:
    ensure  => latest,
    require => Yumrepo['PGDG']
  }

  package {
    'supervisor':
      ensure  => latest,
      require => Yumrepo['EPEL']
  }

  package {
    'elasticsearch':
      ensure  => latest,
      require => [ Yumrepo['elasticsearch'], Package['java-1.7.0-openjdk'] ]
  }

  file {
    '/etc/socorro':
      ensure => directory;

    'pg_hba.conf':
      ensure  => file,
      path    => '/var/lib/pgsql/9.3/data/pg_hba.conf',
      source  => 'puppet:///modules/socorro/var_lib_pgsql_9.3_data/pg_hba.conf',
      owner   => 'postgres',
      group   => 'postgres',
      require => [
        Package['postgresql93-server'],
      ],
      notify  => Service['postgresql-9.3'];

    'pgsql.sh':
      ensure => file,
      path   => '/etc/profile.d/pgsql.sh',
      source => 'puppet:///modules/socorro/etc_profile.d/pgsql.sh',
      owner  => 'root';

    'elasticsearch.yml':
      ensure  => file,
      path    => '/etc/elasticsearch/elasticsearch.yml',
      source  => 'puppet:///modules/socorro/etc_elasticsearch/elasticsearch.yml',
      owner   => 'root',
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch'];
  }

}

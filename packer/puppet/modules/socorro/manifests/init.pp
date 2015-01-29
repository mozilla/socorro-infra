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

    'rabbitmq-server':
      ensure  => stopped,
      enable  => false,
      require => Package['rabbitmq-server'];
  }

  yumrepo {
    'elasticsearch':
      baseurl => 'http://packages.elasticsearch.org/elasticsearch/1.4/centos',
      gpgkey  => 'https://packages.elasticsearch.org/GPG-KEY-elasticsearch';
    'PGDG':
      baseurl => 'http://yum.postgresql.org/9.3/redhat/rhel-$releasever-$basearch',
      gpgkey  => 'http://yum.postgresql.org/RPM-GPG-KEY-PGDG';
  }

  Yumrepo['elasticsearch', 'PGDG'] {
    enabled  => 1,
    gpgcheck => 1
  }

  package {
    'ca-certificates':
      ensure => latest
  }

  package {
    'yum-plugin-fastestmirror':
      ensure  => latest,
      require => Package['ca-certificates']
  }

  package {
    [
      'epel-release',
      'httpd',
      'java-1.7.0-openjdk',
      'mod_wsgi',
      'unzip',
    ]:
    ensure  => latest,
    require => Package['yum-plugin-fastestmirror']
  }

  package {
    [
      'postgresql93-contrib',
      'postgresql93-devel',
      'postgresql93-plperl',
      'postgresql93-server',
    ]:
    ensure  => latest,
    require => [
      Yumrepo['PGDG'],
      Package['ca-certificates']
    ]
  }

  package {
    [
      'rabbitmq-server',
      'supervisor'
    ]:
      ensure  => latest,
      require => Package['epel-release']
  }

  package {
    'elasticsearch':
      ensure  => latest,
      require => [
        Yumrepo['elasticsearch'],
        Package['java-1.7.0-openjdk']
      ]
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
      require => Package['postgresql93-server'],
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

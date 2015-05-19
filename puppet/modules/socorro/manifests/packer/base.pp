# Set up basic Socorro requirements.
class socorro::packer::base {

  include socorro

  service {
    'nginx':
      ensure  => stopped,
      enable  => false,
      require => Package['nginx'];

    'postgresql-9.3':
      ensure  => stopped,
      enable  => false,
      require => Package['postgresql93-server'];

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
    [
      'bind-utils',
      'consul-ui',
      'java-1.7.0-openjdk',
      'mod_wsgi',
      'nginx',
      'php-cli',
      'rabbitmq-server',
      'supervisor',
      'unzip'
    ]:
    ensure  => latest,
    require => Package['epel-release', 'yum-plugin-fastestmirror']
  }

  package {
    [
      'postgresql93-contrib',
      'postgresql93-devel',
      'postgresql93-plperl',
      'postgresql93-server'
    ]:
    ensure  => latest,
    require => [
      Yumrepo['PGDG'],
      Package['ca-certificates']
    ]
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

  package {
    'ca-certificates':
      ensure  => latest,
      require => Exec['yum_ipv4_check']
  }

  package {
    'socorro-public-repo':
      ensure   => present,
      source   => 'https://s3-us-west-2.amazonaws.com/org.mozilla.crash-stats.packages-public/el/7/noarch/socorro-public-repo-1-1.el7.centos.noarch.rpm',
      provider => 'rpm'
  }

  package {
    [
      'epel-release',
      'git',
      'yum-plugin-fastestmirror'
    ]:
    ensure  => latest,
    require => Package['ca-certificates']
  }

  package {
    [
      'consul',
      'envconsul',
      'hiera-consul',
      'hiera-s3',
      'socorro',
      'mozilla-snappy'
    ]:
    ensure  => latest,
    require => Package[
      'socorro-public-repo',
      'epel-release',
      'yum-plugin-fastestmirror'
    ]
  }

  file {
    'selinux_config':
      path   => '/etc/selinux/config',
      source => 'puppet:///modules/socorro/etc_selinux/config',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    'sshd_config':
      path   => '/etc/ssh/sshd_config',
      source => 'puppet:///modules/socorro/etc_ssh/sshd_config',
      owner  => 'root',
      group  => 'root',
      mode   => '0644'
  }

  file {
    '/etc/consul/common.json':
      source  => 'puppet:///modules/socorro/etc_consul/common.json',
      owner   => 'root',
      group   => 'consul',
      mode    => '0640',
      require => Package['consul'];

    '/etc/sysconfig/consul':
      source  => 'puppet:///modules/socorro/etc_sysconfig/consul',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package['consul'];

    # Puppet is already running when this lands, thus it is not available now.
    # It is available on any subsequent run, such as during role provision.
    '/etc/puppet/hiera.yaml':
      source => 'puppet:///modules/socorro/etc_puppet/hiera.yaml',
      owner  => 'root',
      group  => 'root',
      mode   => '0644'
  }

  exec {
    'install-ec2-metadata':
      path    => '/usr/bin',
      command => '/bin/wget http://s3.amazonaws.com/ec2metadata/ec2-metadata -P /bin/ && /usr/bin/chmod 755 /bin/ec2-metadata',
      creates => '/bin/ec2-metadata'
  }
}

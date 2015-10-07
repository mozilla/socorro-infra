# Set up basic Socorro requirements.
class socorro::packer::base {

  include socorro

  service {
    'nginx':
      ensure  => stopped,
      enable  => false,
      require => Package['nginx'];

    'postgresql-9.4':
      ensure  => stopped,
      enable  => false,
      require => Package['postgresql94-server'];

    'datadog-agent':
      ensure  => stopped,
      enable  => false,
      require => Package['datadog-agent'];

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
      baseurl => 'http://yum.postgresql.org/9.4/redhat/rhel-$releasever-$basearch',
      gpgkey  => 'http://yum.postgresql.org/RPM-GPG-KEY-PGDG';
    'datadog-agent':
      baseurl => 'http://yum.datadoghq.com/rpm/x86_64/',
  }

  Yumrepo['elasticsearch', 'PGDG'] {
    enabled  => 1,
    gpgcheck => 1
  }

  Yumrepo['datadog-agent'] {
    enabled  => 1,
    gpgcheck => 0
  }

  package {
    'datadog-agent':
      ensure  => latest,
      require => Yumrepo['datadog-agent']

  }

  package {
    [
      'bind-utils',
      'consul-ui',
      'java-1.8.0-openjdk',
      'mod_wsgi',
      'nginx',
      'php-cli',
      'python-pip',
      'rabbitmq-server',
      'supervisor',
      'unzip',
      'wget'
    ]:
    ensure  => latest,
    require => Package['epel-release', 'yum-plugin-fastestmirror']
  }

  package {
    [
      'postgresql94-contrib',
      'postgresql94-devel',
      'postgresql94-server'
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
        Package['java-1.8.0-openjdk']
      ]
  }

  package {
    'elasticsearch-plugin-cloud-aws':
      ensure  => latest,
      require => Package['elasticsearch']
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

    '/home/socorro':
      ensure => directory,
      owner  => 'socorro',
      group  => 'nginx';

    '/home/socorro/crashes',
      ensure  => directory,
      owner   => 'socorro',
      group   => 'nginx',
      require => File['/home/socorro'];
  }


  # RHEL-alike and pip provider relationship status: It's Complicated
  # Workaround is to have a symlink called "pip-python" because reasons.
  # https://github.com/evenup/evenup-curator/issues/24 for example.
  file {
    '/usr/bin/pip-python':
      ensure  => link,
      target  => '/usr/bin/pip',
      require => Package['python-pip']
  }

  package {
    'awscli':
      ensure   => latest,
      provider => 'pip',
      require  => File['/usr/bin/pip-python']
  }

  package {
    'consulate':
      ensure   => latest,
      provider => 'pip',
      require  => Package['python-pip']
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

  # This little script is used to quickly pull out EC2 metadata via CLI.
  # TODO: Package it properly.
  exec {
    'install-ec2-metadata':
      path    => '/bin',
      cwd     => '/bin',
      command => 'curl -O https://s3.amazonaws.com/ec2metadata/ec2-metadata',
      creates => '/bin/ec2-metadata'
  }

  file {
    '/bin/ec2-metadata':
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => Exec['install-ec2-metadata']
  }

}

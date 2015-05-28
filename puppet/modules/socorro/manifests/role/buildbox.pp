# Set up a buildbox node.
class socorro::role::buildbox {

include socorro::role::common

# Set config variables to inject into templates
$aws_access_key=hiera("${::environment}/buildbox_aws_access_key")
$aws_secret_access_key=hiera("${::environment}/buildbox_aws_secret_access_key")
$aws_default_region=hiera("${::environment}/buildbox_default_aws_region")
$buildbox_rpm_key=hiera("${::environment}/buildbox_rpm_key")
$secret_bucket=hiera("${::environment}/secret_bucket")

  service {
    'iptables':
      ensure => stopped,
      enable => false;

    'rabbitmq-server':
      ensure => running,
      enable => true;

    'postgresql-9.3':
      ensure  => running,
      enable  => true,
      require => Exec['postgres-trust-local'];

    'elasticsearch':
      ensure => running,
      enable => true;

    'jenkins':
      ensure => running,
      enable => true;
  }

  file {
    '/data':
      ensure => directory,
      owner  => 'centos',
      mode   => '0755'
  }

  file {
    '/etc/jenkins':
      ensure => directory,
      owner  => 'centos',
      mode   => '0755'
  }

  file {
    'aws-config.sh':
      ensure  => file,
      content => template('socorro/etc_jenkins/aws-config.sh.erb'),
      path    => '/etc/jenkins/aws-config.sh',
      owner   => 'centos',
      mode    => '0755',
      require => File['/etc/jenkins']
  }

  file {
    'passphrase.txt':
      ensure  => file,
      path    => '/etc/jenkins/passphrase.txt',
      content => template('socorro/etc_jenkins/passphrase.txt.erb'),
      owner   => 'centos',
      require => File['/etc/jenkins']
  }

  file {
    '.rpmmacros':
      ensure  => file,
      path    => '/home/centos/.rpmmacros',
      source  => 'puppet:///modules/socorro/etc_jenkins/rpmmacros',
      owner   => 'centos'
  }

  file {
    'manage_repo.sh':
      ensure  => file,
      content => template('socorro/bin_manage_repo/manage_repo.sh.erb'),
      path    => '/home/centos/manage_repo.sh',
      owner   => 'centos',
      mode    => '0755',
  }

  file {
    'pg_hba.conf':
      ensure  => file,
      path    => '/var/lib/pgsql/9.3/data/pg_hba.conf',
      source  => 'puppet:///modules/socorro/var_lib_pgsql_9.3_data/pg_hba.conf',
      owner   => 'postgres',
      group   => 'postgres',
      require => Exec['postgres-initdb']
  }

  # Not gonna lie: this series of execs is really, really gross.
  exec {
    'postgres-initdb':
      path    => '/usr/bin:/usr/sbin',
      command => '/usr/pgsql-9.3/bin/postgresql93-setup initdb'
  }

  exec {
    'postgres-trust-local':
      path    => '/usr/bin',
      command => 'sed -i "s:ident:trust:" /var/lib/pgsql/9.3/data/pg_hba.conf',
      require => File['pg_hba.conf']
  }

  exec {
    'postgres-test-role':
      path    => '/usr/bin:/bin',
      cwd     => '/var/lib/pgsql',
      user    => 'postgres',
      command => 'psql template1 -c "create user test with encrypted password \'aPassword\' superuser"',
      unless  => 'psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname=\'test\'" | grep -q 1',
      require => Service['postgresql-9.3']
  }

  exec {
    'postgres-test-database_test':
      path    => '/usr/bin:/bin',
      cwd     => '/var/lib/pgsql',
      user    => 'postgres',
      command => 'psql -c \'create database socorro_test;\' -U postgres',
      require => Exec['postgres-test-role'];

    'postgres-test-database_integration_test':
      path    => '/usr/bin:/bin',
      cwd     => '/var/lib/pgsql',
      user    => 'postgres',
      command => 'psql -c \'create database socorro_integration_test;\' -U postgres',
      require => Exec['postgres-test-role'];

    'postgres-test-database_migration_test':
      path    => '/usr/bin:/bin',
      cwd     => '/var/lib/pgsql',
      user    => 'postgres',
      command => 'psql -c \'create database socorro_migration_test;\' -U postgres',
      require => Exec['postgres-test-role'];
  }

}

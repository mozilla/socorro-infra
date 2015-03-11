# Set up a buildbox node.
class socorro::role::buildbox {

  service {
    'iptables':
      ensure => stopped,
      enable => false;

    'rabbitmq-server':
      ensure  => running,
      enable  => true;

    'postgresql-9.3':
      ensure  => running,
      enable  => true,
      require => Exec['postgres-initdb'];

    'elasticsearch':
      ensure  => running,
      enable  => true;
  }

  # Not gonna lie: this series of execs is really, really gross.
  exec {
    'postgres-trust-local':
      command => 'perl -p -i -e "s/ident/trust/" /var/lib/pgsql/9.3/data/pg_hba.conf';
  }

  exec {
    'postgres-initdb':
      command => '/usr/pgsql-9.3/bin/postgresql93-setup initdb',
      require => Exec['postgres-trust-local'];
  }

  exec {
    'postgres-test-role':
      path    => '/usr/bin:/bin',
      cwd     => '/var/lib/pgsql',
      user    => 'postgres',
      command => 'psql template1 -c "create user test with encrypted password \'aPassword\' superuser"',
      unless  => 'psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname=\'test\'" | grep -q 1',
      require => Service['postgresql-9.3'];
  }

  exec {
    'postgres-test-database_test':
      path    => '/usr/bin:/bin',
      cwd     => '/var/lib/pgsql',
      user    => 'postgres',
      command => 'psql -c \'create database socorro_test;\' -U postgres',
      require => Exec['postgres-test-role'];
  }

  exec {
    'postgres-test-database_integration_test':
      path    => '/usr/bin:/bin',
      cwd     => '/var/lib/pgsql',
      user    => 'postgres',
      command => 'psql -c \'create database socorro_integration_test;\' -U postgres',
      require => Exec['postgres-test-role'];
  }

  exec {
    'postgres-test-database_migration_test':
      path    => '/usr/bin:/bin',
      cwd     => '/var/lib/pgsql',
      user    => 'postgres',
      command => 'psql -c \'create database socorro_migration_test;\' -U postgres',
      require => Exec['postgres-test-role'];
  }

}

# Elements common to all Socorro boxes.
class socorro {

  service {
    'consul':
      ensure  => running,
      enabled => true,
      require => File[
        '/etc/consul/common.json',
        '/etc/sysconfig/consul'
      ];

    'sshd':
      ensure  => running,
      enable  => true,
      require => File['sshd_config']
  }

  package {
    'ca-certificates':
      ensure => latest
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
      'hiera-s3'
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
      require => Package['consul']
  }

}

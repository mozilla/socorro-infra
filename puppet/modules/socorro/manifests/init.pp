# Elements common to all Socorro boxes.
class socorro {

  # Yum will sometimes resolve and attempt to use IPv6 addresses. This is a
  # problem in AWS and can cause random errors (fun!).
  $yum_ipv4_exec = $::bios_version ? {
    /.*amazon.*/ => '/usr/bin/echo "ip_resolve=4" >> /etc/yum.conf',
    default      => '/usr/bin/true'
  }
  exec {
    'yum_ipv4_check':
      command => $yum_ipv4_exec
  }

  service {
    'consul':
      ensure  => running,
      enable  => true,
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
      require => Package['consul'];

    # Puppet is already running when this lands, thus it is not available now.
    # It is available on any subsequent run, such as during role provision.
    '/etc/puppet/hiera.yaml':
      source => 'puppet:///modules/socorro/etc_puppet/hiera.yaml',
      owner  => 'root',
      group  => 'root',
      mode   => '0644'
  }

}

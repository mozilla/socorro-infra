# Elements common to all Socorro boxes.
class socorro {

  service {
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
      ensure => file,
      path   => '/etc/selinux/config',
      source => 'puppet:///modules/socorro/etc_selinux/config',
      owner  => 'root',
      group  => 'root',
      mode   => '0644';

    'sshd_config':
      ensure => file,
      path   => '/etc/ssh/sshd_config',
      source => 'puppet:///modules/socorro/etc_ssh/sshd_config',
      owner  => 'root',
      group  => 'root',
      mode   => '0644'
  }

}

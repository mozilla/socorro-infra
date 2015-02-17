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
    [
      'epel-release',
      'yum-plugin-fastestmirror'
    ]:
    ensure  => latest,
    require => [
      Package['ca-certificates']
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

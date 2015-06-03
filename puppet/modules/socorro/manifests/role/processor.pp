# Set up a processor node.
class socorro::role::processor {

include socorro::role::common

  exec {
    'format-symbol-cache':
      path    => '/usr/sbin',
      command => 'mkfs.ext4 /dev/xvdc'
  }

  mount {
    '/mnt':
      ensure  => mounted,
      device  => '/dev/xvdc',
      fstype  => 'ext4',
      options => 'defaults',
      require => Exec['format-symbol-cache']
  }

  file {
    '/mnt/symbolcache':
      ensure  => directory,
      owner   => 'socorro',
      require => Mount['/mnt']
  }

  service {
    'socorro-processor':
      ensure  => running,
      enable  => true,
      require => [
        Exec['join_consul_cluster'],
        File['/mnt/symbolcache']
      ]
  }

}

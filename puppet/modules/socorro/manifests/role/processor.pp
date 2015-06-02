# Set up a processor node.
class socorro::role::processor {

include socorro::role::common

  exec {
    'format-symbol-cache':
      path    => '/usr/sbin',
      command => 'mkfs.ext4 /dev/xvdc'
  }

  mount {
    '/tmp/symbols':
      ensure  => mounted,
      device  => '/dev/xvdc',
      fstype  => 'ext4',
      options => 'defaults',
      require => Exec['format-symbol-cache']
  }

  File['/tmp/symbols'] {
      require => Mount['/tmp/symbols']
  }

  service {
    'socorro-processor':
      ensure  => running,
      enable  => true,
      require => [
        Exec['join_consul_cluster'],
        File['/tmp/symbols']
      ]
  }

}

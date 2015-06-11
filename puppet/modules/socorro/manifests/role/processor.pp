# Set up a processor node.
class socorro::role::processor {

  include socorro::role::common

  # Symbols uses a hierarchy of directories that should be on the same
  # block device for performance reasons.
  $symbols_base = '/mnt/symbols'
  $symbols_dirs = [
    "${symbols_base}/cache",
    "${symbols_base}/tmp"
  ]

  file {
    $symbols_base:
      ensure => directory
  }

  # There is an edge-case interaction between cloud-init and *some* instance
  # types that causes EBS volumes to be pre-mounted.
  # https://bugzilla.mozilla.org/show_bug.cgi?id=1173085
  exec {
    'check-premounted-ebs':
      path    => '/bin',
      command => 'umount /dev/xvdb',
      onlyif  => 'mount | grep xvdb'
  }

  exec {
    'format-symbols-cache':
      path    => '/usr/sbin',
      command => 'mkfs.ext4 /dev/xvdb',
      require => Exec['check-premounted-ebs']
  }

  mount {
    $symbols_base:
      ensure  => mounted,
      device  => '/dev/xvdb',
      fstype  => 'ext4',
      options => 'defaults',
      require => [
        Exec['format-symbols-cache'],
        File[$symbols_base]
      ]
  }

  file {
    $symbols_dirs:
      ensure  => directory,
      owner   => 'socorro',
      require => Mount[$symbols_base]
  }

  service {
    'socorro-processor':
      ensure  => running,
      enable  => true,
      require => [
        Exec['join_consul_cluster'],
        File[$symbols_dirs]
      ]
  }

}

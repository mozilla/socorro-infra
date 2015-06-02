# Set up a processor node.
class socorro::role::processor {

include socorro::role::common

  # FIXME - remove this when bug 1170420 is fixed in Socorro Processor
  file {
    '/tmp/symbols':
      ensure => 'directory',
      owner  => socorro
  }

  service {
    'socorro-processor':
      ensure  => running,
      enable  => true,
      require => [
        Exec['join_consul_cluster'],
        File['/tmp/symbols']
      ];
  }

}

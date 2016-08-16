# Set up a submitter node.
class socorro::role::stagesubmitter {

include socorro::role::common

  service {
    'nginx':
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/nginx/conf.d/socorro-stagesubmitter.conf'];

    'socorro-stagesubmitter':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster']
  }

  file {
    '/etc/nginx/conf.d/socorro-stagesubmitter.conf':
      source  => 'puppet:///modules/socorro/etc_nginx/conf_d/socorro-stagesubmitter.conf',
      owner   => 'root',
      group   => 'nginx',
      mode    => '0664',
      require => File['/etc/nginx/nginx.conf']
  }

}

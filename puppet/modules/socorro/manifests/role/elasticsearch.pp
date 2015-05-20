# Set up an elasticsearch node.
class socorro::role::elasticsearch {

include socorro::role::common

  service {
    'elasticsearch':
      ensure  => running,
      enable  => true,
      require => Exec['join_consul_cluster'];
  }

  file {
    '/etc/dd-agent/conf.d/elastic':
      source => 'puppet:///modules/socorro/etc_dd_agent/elastic',
      owner  => 'dd-agent',
      group  => 'dd-agent',
      mode   => '0640';
  }
}

# Set up an elasticsearch node.
class socorro::role::elasticsearch {

include socorro::role::common

  # ES will hit default ulimits rather quickly.
  file { '/etc/security/limits.d/90-elasticsearch.conf':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/socorro/etc_security_limits.d/90-elasticsearch.conf'
  }

  # These switches determine the role of the node: master, interface, or data.
  $es_master = $::elasticsearch_role ? {
    'master' => true,
    default  => false
  }
  $es_interface = $::elasticsearch_role ? {
    'interface' => true,
    default     => false
  }
  $es_data = $::elasticsearch_role ? {
    'data'  => true,
    default => false
  }

  # The values from the switches above are applied in elasticsearch.yml .
  file { '/etc/elasticsearch/elasticsearch.yml':
    owner   => 'root',
    group   => 'elasticsearch',
    mode    => '0644',
    content => template('socorro/etc_elasticsearch/elasticsearch.yml.erb')
  }

  service {
    'elasticsearch':
      ensure  => running,
      enable  => true,
      require => [
        Exec['join_consul_cluster'],
        File['/etc/security/limits.d/90-elasticsearch.conf'],
        File['/etc/elasticsearch/elasticsearch.yml']
      ]
  }

}

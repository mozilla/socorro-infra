# Set up an elasticsearch node.
class socorro::role::elasticsearch {

include socorro::role::common

  # ES will hit default ulimits rather quickly.
  file {
    '/etc/security/limits.d/90-elasticsearch.conf':
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
  file {
    '/etc/elasticsearch/elasticsearch.yml':
      owner   => 'root',
      group   => 'elasticsearch',
      mode    => '0644',
      content => template('socorro/etc_elasticsearch/elasticsearch.yml.erb')
  }

  file {
    '/var/lib/elasticsearch':
      owner => 'elasticsearch'
  }

  service {
    'elasticsearch':
      ensure  => running,
      enable  => true,
      require => [
        Exec['join_consul_cluster'],
        File['/etc/security/limits.d/90-elasticsearch.conf'],
        File['/etc/elasticsearch/elasticsearch.yml'],
        File['/var/lib/elasticsearch']
      ]
  }

  # Data nodes have an attached EBS volume that needs to be formatted and
  # mounted before the service is activated.
  if $::elasticsearch_role == 'data' {
    exec {
      'format-es-data':
        path    => '/usr/sbin',
        command => 'mkfs.ext4 /dev/xvdb'
    }

    mount {
      '/var/lib/elasticsearch':
        ensure  => mounted,
        device  => '/dev/xvdb',
        fstype  => 'ext4',
        options => 'defaults',
        require => Exec['format-es-data']
    }

    File['/var/lib/elasticsearch'] {
      require => Mount['/var/lib/elasticsearch']
    }
  }

if $::elasticsearch_role == 'interface'  {
    file {
    '/etc/dd-agent/conf.d/elasticsearch.yaml':
      mode   => '0640',
      owner  => 'dd-agent',
      source => 'puppet:///modules/socorro/etc_dd-agent/elasticsearch.yaml',
      notify => Service['datadog-agent']
  }

  service {
    'datadog-agent':
      ensure    => running,
      enable    => true,
      hasstatus => false,
      pattern   => 'datadog-agent'
  }
}
}

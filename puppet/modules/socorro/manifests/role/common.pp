# Elements common to all Socorro roles.
class socorro::role::common {

  # We expect this to come from the secret S3 bucket
  $consul_hostname = hiera("${::environment}/consul_hostname")
  exec {
      'join_consul_cluster':
        command => "/usr/bin/consul join ${consul_hostname}"
  }

}

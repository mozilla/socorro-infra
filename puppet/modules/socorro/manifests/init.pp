# Elements common to all Socorro boxes.
class socorro {

  # Yum will sometimes resolve and attempt to use IPv6 addresses. This is a
  # problem in AWS and can cause random errors (fun!).
  $yum_ipv4_exec = $::bios_version ? {
    /.*amazon.*/ => '/usr/bin/echo "ip_resolve=4" >> /etc/yum.conf',
    default      => '/usr/bin/true'
  }
  exec {
    'yum_ipv4_check':
      command => $yum_ipv4_exec
  }

  service {
    'consul':
      ensure  => running,
      enable  => true,
      require => File['/etc/consul/common.json',
                      '/etc/sysconfig/consul'
      ];

    'sshd':
      ensure  => running,
      enable  => true,
      require => File['sshd_config']
  }
}

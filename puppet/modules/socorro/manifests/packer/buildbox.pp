# Box used for building Socorro components.
class socorro::packer::buildbox {

  # The base class has much of what we need for testing.
  include socorro::packer::base

  yumrepo {
    'jenkins':
      baseurl  => 'http://pkg.jenkins-ci.org/redhat/',
      gpgkey   => 'http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key',
      gpgcheck => 1,
      enabled  => 1
  }

  package {
    [ 'bind-libs',
      'bzip2',
      'c-ares',
      'cpp',
      'createrepo',
      'createrepo_c',
      'createrepo_c-libs',
      'cyrus-sasl',
      'cyrus-sasl-devel',
      'deltarpm',
      'dwz',
      'elfutils',
      'emacs-filesystem',
      'gcc-c++',
      'gdb',
      'glibc-devel',
      'glibc-headers',
      'gpm-libs',
      'http-parser',
      'java-1.7.0-openjdk-devel',
      'kernel-headers',
      'libcurl-devel',
      'libgcrypt-devel',
      'libgpg-error-devel',
      'libmpc',
      'libstdc++-devel',
      'libuv',
      'libxml2-devel',
      'libxml2-python',
      'libxslt-devel',
      'make',
      'mercurial',
      'mock',
      'mpfr',
      'neon',
      'nodejs',
      'nodejs-less',
      'openldap-devel',
      'packer',
      'pakchois',
      'patch',
      'perl-Thread-Queue',
      'perl-srpm-macros',
      'pigz',
      'python-deltarpm',
      'python-devel',
      'python-pip',
      'python-virtualenv',
      'redhat-rpm-config',
      'rpm-build',
      'rpm-sign',
      'rpmdevtools',
      'rsync',
      'ruby-devel',
      'strace',
      'subversion',
      'subversion-libs',
      'terraform',
      'time',
      'usermode',
      'v8',
      'vim-common',
      'vim-enhanced',
      'vim-filesystem',
      'xz-devel',
      'ycssmin',
      'zlib-devel'
    ]:
    ensure  => latest,
    require => Package['epel-release', 'yum-plugin-fastestmirror']
  }

  package { 'jenkins':
      ensure  => installed,
      require => Yumrepo['jenkins'],
  }

  file {
    '/etc/profile.d/rpmbuild.sh':
      ensure => file,
      source => 'puppet:///modules/socorro/etc_profile.d/rpmbuild.sh',
      mode   => '0755',
      owner  => 'root',
      group  => 'root'
  }

  file {
    '/etc/sysconfig/jenkins':
      source  => 'puppet:///modules/socorro/etc_jenkins/etc-sysconfig-jenkins',
      owner   => 'root',
      group   => 'root',
      require => Package['jenkins'];

    '/var/lib/jenkins':
      ensure  => directory,
      owner   => 'centos',
      mode    => '0664',
      require => Package['jenkins'];

    '/usr/lib/jenkins':
      ensure  => directory,
      owner   => 'centos',
      mode    => '0664',
      require => Package['jenkins'];

    '/var/log/jenkins':
      ensure  => directory,
      owner   => 'centos',
      mode    => '0664',
      require => Package['jenkins'];

    '/var/cache/jenkins':
      ensure  => directory,
      owner   => 'centos',
      mode    => '0664',
      require => Package['jenkins'];

  }

  # RHEL-alike and pip provider relationship status: It's Complicated
  # Workaround is to have a symlink called "pip-python" because reasons.
  # https://github.com/evenup/evenup-curator/issues/24 for example.
  file {
    '/usr/bin/pip-python':
      ensure  => link,
      target  => '/usr/bin/pip',
      require => Package['python-pip']
  }

  package {
    'awscli':
      ensure   => latest,
      provider => 'pip',
      require  => File['/usr/bin/pip-python']
  }

  package {
    'boto':
      ensure   => latest,
      provider => 'pip',
      require  => File['/usr/bin/pip-python']
  }

  package {
    'fpm':
      ensure   => latest,
      provider => 'gem',
      require  => Package['ruby-devel']
  }

}

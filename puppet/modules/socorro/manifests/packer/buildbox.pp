# Box used for building Socorro components.
class socorro::packer::buildbox {

  # The base class has much of what we need for testing.
  include socorro::packer::base

  package {
    [
      'createrepo',
      'gcc-c++',
      'golang',
      'java-1.7.0-openjdk-devel',
      'libcurl-devel',
      'libxml2-devel',
      'libxslt-devel',
      'nodejs-less',
      'make',
      'mock',
      'mercurial',
      'openldap-devel',
      'python-devel',
      'python-virtualenv',
      'rpm-build',
      'rpm-sign',
      'rpmdevtools',
      'rsync',
      'ruby-devel',
      'subversion',
      'time',
      'vim-enhanced',
    ]:
    ensure  => latest,
    require => Package['epel-release', 'yum-plugin-fastestmirror']
  }

  file {
    '/etc/profile.d/rpmbuild.sh':
      ensure => file,
      source => 'puppet:///modules/socorro/etc_profile.d/rpmbuild.sh',
      owner  => 'root',
      group  => 'root'
  }

  package {
    'fpm':
      ensure   => latest,
      provider => 'gem',
      require  => Package['ruby-devel']
  }

}

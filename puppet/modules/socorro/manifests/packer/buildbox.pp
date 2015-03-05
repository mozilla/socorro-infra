# Box used for building Socorro components.
class socorro::packer::buildbox {

  # Don't forget to include the common components!
  include socorro

  package {
    [
      'createrepo',
      'gcc-c++',
      'java-1.7.0-openjdk',
      'java-1.7.0-openjdk-devel',
      'libcurl-devel',
      'libxml2-devel',
      'libxslt-devel',
      'make',
      'mock',
      'openldap-devel',
      'python-devel',
      'python-pip',
      'rpm-build',
      'rpm-sign',
      'rpmdevtools',
      'rsync',
      'ruby-devel',
      'subversion',
      'time',
      'unzip',
      'vim'
    ]:
    ensure  => latest,
    require => Package['epel-release']
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

  file {
    '/etc/profile.d/rpmbuild.sh':
      ensure => file,
      source => 'puppet:///modules/socorro/etc_profile.d/rpmbuild.sh',
      owner  => 'root',
      group  => 'root'
  }


}

# Box used for building Socorro components.
class socorro::buildbox {

  # Don't forget to include the common components!
  include socorro

  package {
    [
      'gcc-c++',
      'git',
      'java-1.7.0-openjdk',
      'java-1.7.0-openjdk-devel',
      'libcurl-devel',
      'libxml2-devel',
      'libxslt-devel',
      'make',
      'openldap-devel',
      'python-devel',
      'rpm-build',
      'rsync',
      'ruby-devel',
      'subversion',
      'time',
      'unzip'
    ]:
    ensure  => latest,
    require => Package['epel-release']
  }
}

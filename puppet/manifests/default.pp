Exec {
  logoutput => 'on_failure'
}

node default {
  case $::packer_profile {
    'base': { include socorro::base }
    'buildbox': { include socorro::buildbox }
    default: {
      err("'${::packer_profile}' is not a valid Packer profile label.")
      fail('Invalid packer_profile.')
    }
  }
}

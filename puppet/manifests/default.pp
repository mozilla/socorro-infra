Exec {
  logoutput => 'on_failure'
}

node default {
  case $::packer_profile {
    'base': { include socorro::packer::base }
    'buildbox': { include socorro::packer::buildbox }
    default: {}
  }

  case $::socorro_role {
    'consul': { include socorro::role::consul }
    'symbolapi': { include socorro::role::symbolapi }
    default: {}
  }
}

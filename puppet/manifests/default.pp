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
    'buildbox': { include socorro::role::buildbox }
    'symbolapi': { include socorro::role::symbolapi }
    'admin': { include socorro::role::admin }
    'analysis': { include socorro::role::analysis }
    'collector': { include socorro::role::collector }
    'elasticsearch': { include socorro::role::elasticsearch }
    'postgres': { include socorro::role::postgres }
    'processor': { include socorro::role::processor }
    'rabbitmq': { include socorro::role::rabbitmq }
    'webapp': { include socorro::role::webapp }
    default: {}
  }
}

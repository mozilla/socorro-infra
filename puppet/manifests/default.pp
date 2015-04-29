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
    'admin': { include socorro::role::admin }
    'analysis': { include socorro::role::analysis }
    'buildbox': { include socorro::role::buildbox }
    'collector': { include socorro::role::collector }
    'consul': { include socorro::role::consul }
    'elasticsearch': { include socorro::role::elasticsearch }
    'postgres': { include socorro::role::postgres }
    'processor': { include socorro::role::processor }
    'rabbitmq': { include socorro::role::rabbitmq }
    'symbolapi': { include socorro::role::symbolapi }
    'webapp': { include socorro::role::webapp }
    default: {}
  }
}

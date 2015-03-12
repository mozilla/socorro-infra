# Set up a admin node.
class socorro::role::admin {

  package {
    'socorro':
      ensure=> latest
  }

}

import "wren-package" for WrenPackage, Dependency

class Package is WrenPackage {
  construct new() {}
  name { "xsequence" }
  version { "3.2.0" }
  dependencies {
    return []
  }
}

Package.new().default()
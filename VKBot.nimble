version       = "0.1.0"
author        = "Daniil Yarancev"
description   = "VKBot - command bot for largest CIS social network - VKontakte"
license       = "MIT"
srcDir = "src"
bin = @["vkbot"]

requires "nim >= 0.16.1"

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libssl-dev"
  else:
    foreignDep "openssl"

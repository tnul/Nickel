# Package
version       = "0.0.4"
author        = "Daniil Yarancev"
description   = "VKBot - command bot for largest CIS social network - VKontakte"
license       = "MIT"
srcDir = "src"
bin = @["vkbot.linux64", "vkbot.linux32", "vkbot.linux", "vkbot.win64.exe", "vkbot.win32.exe", "vkbot.win.exe"]

requires "nim >= 0.16.1"

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libssl-dev"
  else:
    foreignDep "openssl"

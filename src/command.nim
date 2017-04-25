import macros, tables, types

var 
  commands* = initTable[string, ModuleFunction]()
  anyCommands*: seq[ModuleFunction] = @[]

proc handle*(handler: ModuleFunction, cmds: varargs[string]) = 
  ## Процедура для добавления нескольких комманд для данного обработчика
  ## Пример - call.handle("привет", "прив", "ку"), где call - это ModuleFunction
  for cmd in cmds:
    if cmd == "": anyCommands.add(handler)
    else: commands[cmd] = handler

proc anyCommand*(handler: ModuleFunction) = 
  anyCommands.add(handler)

# Все модули объявляются во время компиляции, 
# поэтому используется {.compiletime.}
var 
  modules* {.compiletime.}: seq[string] = @[]
  usages* {.compiletime.}: seq[string] = @[]
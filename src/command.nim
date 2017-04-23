import macros, tables, types

var commands* = initTable[string, ModuleFunction]()

proc handle*(handler: ModuleFunction, cmds: varargs[string]) = 
  ## Процедура для добавления нескольких комманд для данного обработчика
  ## Пример - call.handle("привет", "прив", "ку"), где call - это ModuleFunction
  for cmd in cmds:
    commands[cmd] = handler

# Все модули объявляются во время компиляции, 
# поэтому используется {.compiletime.}
var 
  modules* {.compiletime.}: seq[string] = @[]
  usages* {.compiletime.}: seq[string] = @[]
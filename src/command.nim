import macros, tables, types

var commands* = initTable[string, ModuleFunction]()

proc handle*(handler: ModuleFunction, cmds: varargs[string]) = 
  ## Процедура для добавления нескольких комманд для данного хендлера
  ## Пример - call.handle("привет", "прив", "ку"), call - PluginFunction
  for cmd in cmds:
    commands[cmd] = handler

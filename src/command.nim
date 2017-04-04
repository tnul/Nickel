import macros, tables, types

var commands*: Table[string, PluginFunction] = initTable[string, PluginFunction]()

proc handle*(handler: PluginFunction, cmds: varargs[string]) = 
  ## Процедура для добавления нескольких комманд для данного хендлера
  ## Пример - call.handle("привет", "прив", "ку"), call - PluginFunction
  for cmd in cmds:
    commands[cmd] = handler

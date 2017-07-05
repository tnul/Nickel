include baseimports
import logging
import macros
var L* = newConsoleLogger()
addHandler(L)
export logging

proc log*(msg: Message, command = false) = 
  ## Логгирует объект сообщения в консоль
  let frm = "https://vk.com/id" & $msg.pid
  # Если нужно логгировать команду
  if command:
    var args = ""
    if len(msg.cmd.args) > 0:
      args = "с аргументами " & $msg.cmd.args
    else:
      args = "без аргументов"
    info("$1 > Команда `$2` $3" % [frm, msg.cmd.name, args])
  else:
    debug("Сообщение `$1` от $2" % [msg.body, frm])

macro logWithLevel*(lvl: Level, body: untyped): untyped = 
  result = newStmtList()
  for elem in body:
    let data = quote do:
      logging.log(`lvl`, `elem`)
    result.add data
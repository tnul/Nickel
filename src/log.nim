include baseimports
import times
import macros

proc log*(data: string, style: ForegroundColor = fgBlack) =
  ## Выводит сообщение в консоль с указанием времени 
  let curtime = "[$1] " % [getClockStr()]
  styledWriteLine(stdout, fgBlue, curtime, style, data)

proc log*(msg: Message, command: bool) = 
  ## Логгирует объект сообщения в консоль
  let frm = "https://vk.com/id" & $msg.pid
  if command:
    var args = ""
    if len(msg.cmd.args) > 0:
      args = "с аргументами " & $msg.cmd.args
    else:
      args = "без аргументов"
    # Зелёным цветом
    log("$1 > Команда `$2` $3" % [frm, msg.cmd.name, args], fgGreen)
  else:
    # Голубым цветом
    log("Сообщение `$1` от $2" % [msg.body, frm], fgCyan)

macro logWithStyle*(style: ForegroundColor, body: untyped): untyped = 
  result = newStmtList()
  # проверяем, что body - список выражений
  expectKind body, nnkStmtList
  for elem in body:
    result.add quote do:
      `elem`.log(`style`)

system.addQuitProc(resetAttributes)

template logError*(data: string) = 
  ## Логгирует ошибку
  data.log(fgRed)

template logWarning*(data: string) = 
  ## Логгирует предупреждение
  data.log(fgYellow)

template logSuccess*(data: string) = 
  ## Логгирует успех
  data.log(fgGreen)

template logHint*(data: string) = 
  ## Логгирует подсказку
  data.log(fgCyan)

template logFatal*(data: string) = 
  ## Логгирует ошибку и выключает бота
  logError(data)
  # Если мы на Windows - вызываем команду "pause", чтобы окно с ботом не
  # закрылось сразу, если бот запускался не через консоль, а через GUI
  when defined(windows):
    discard execShellCmd("pause")
  quit(1)
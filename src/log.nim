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
      args = "с аргументами " & msg.cmd.args.join(", ")
    else:
      args = "без аргументов"
    # Зелёным цветом
    log("$1 > Команда `$1` $2" % [frm, msg.cmd.name, args], fgGreen)
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
    # Скобки
    #expectKind elem, nnkPar
    # Длина - 1 элемент
    #expectLen elem, 1
    # Получаем то, что нам нужно вывести
    
    # Добавляем выражение к результату
    #result.add quote do:
    #  log `style` `toWrite`

system.addQuitProc(resetAttributes)


template logError*(data: string) = 
  data.log(fgRed)

template logWarning*(data: string) = 
  data.log(fgYellow)

template logSuccess*(data: string) = 
  data.log(fgGreen)

template logHint*(data: string) = 
  data.log(fgCyan)
import macros
import tables
import strutils
import types
import unicode
import asyncdispatch
import utils
import sequtils
import log

var
  ## Последовательность кортежей вида (команды, имя файла модуля, имя процедуры)
  compileModules* {.compiletime.} = newSeq[
    tuple[cmds: seq[string], fname, pname: string]
  ]()
  ## Последовательность всех команд
  commands* {.compiletime.} = newSeq[string]()

# Импортируем все модули
importModules()

var
  ## Количество принятых ботом сообщений
  msgCount* = 0
  ## Количество принятых ботом команд
  cmdCount* = 0

macro genCommandCaseStmt*(src, dest): untyped =
  ## Генерирует выражение case/of для всех команд в боте
  # case
  var caseExpr = newTree(nnkCaseStmt)
  # <src>
  caseExpr.add(src)
  # of "команда1", "команда2": вызов процедуры()
  for arg in compileModules:
    let (cmds, fname, pname) = arg
    # Список команд, на которые реагирует этот handler
    var ofTree = newTree(nnkOfBranch)
    for cmd in cmds:
      if cmd == "": continue
      ofTree.add(newStrLitNode(cmd))
    # Вызов процедуры модуля
    ofTree.add(parseExpr("$1(bot.api, msg)" % pname))
    caseExpr.add(ofTree)
  # Если такой команды у нас нет - вызываем пустую асинхронную процедуру
  caseExpr.add newTree(nnkElse, newCall(ident"emptyFuture"))
  # let dest = 
  #   case ...
  result = newLetStmt(dest, caseExpr)

proc processCommand*(bot: VkBot, body: string): Command =
  ## Обрабатывает строку {body} и возвращает тип Command
  # Если тело сообщения пустое
  if body.len == 0:
    return
  # Ищем префикс команды
  var foundPrefix: string
  for prefix in bot.config.prefixes:
    # Если команда начинается с префикса в нижнем регистре
    if unicode.toLower(body).startsWith(prefix):
      foundPrefix = prefix
      break
  # Если мы не нашли префикс - выходим
  if foundPrefix.isNil(): return
  # Получаем команду и аргументы - берём срез строки body без префикса,
  # используем strip для удаления нежелательных пробелов в начале и конце,
  # делим строку на имя команды и значения
  let values = body[len(foundPrefix)..^1].strip().split()
  result.name = values[0]
  result.args = values[1..^1]

proc processMessage*(bot: VkBot, msg: Message) {.async.} = 
  ## Обрабатывает сообщение: логгирует, передаёт события модулям
  # Сохраняем переменную commands (которая есть только во время компиляции)
  # в константу commands
  const commands = commands
  let 
    cmdText = msg.cmd.name
    rusConverted = toRus(cmdText)
    engConverted = toEng(cmdText)
  var
    msg = msg
    isCommand = false
  # TODO: Уменьшить повторение кода в обработке раскладки
  if cmdText in commands:
    isCommand = true

  elif rusConverted in commands:
    msg.cmd.name = rusConverted
    msg.cmd.args.applyIt it.toRus()
    isCommand = true

  elif commands.contains(engConverted):
    msg.cmd.name = engConverted
    msg.cmd.args.applyIt it.toEng()
    isCommand = true
  # Если это команда
  if not isCommand:
    # Если это не команда, и нужно логгировать сообщения
    if bot.config.logMessages:
      msg.log()
    return
  # Увеличиваем счётчик команд
  inc cmdCount
  # Если нужно логгировать команды
  if bot.config.logCommands:
    msg.log(command = true)
  
  proc emptyFuture() {.async.} = discard
  genCommandCaseStmt(msg.cmd.name, fut)
  yield fut
  if fut.failed:
    # handle error
    discard

proc checkMessage*(bot: VkBot, msg: Message) {.async.} = 
  inc msgCount
  await processMessage(bot, msg)

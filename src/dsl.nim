# Стандартная библиотека
import macros
import strutils
import sequtils
# Свои модули
import command
import utils
import vkapi
import types

# Увеличивается с каждым новым обработчиком команды
# Создан для уникальных имён
var count {.compiletime.} = 1

macro command*(cmds: varargs[string], body: untyped): untyped =
  let uniqName = newIdentNode("handler" & $count)
  var 
    usage = ""
    moduleUsages = newSeq[string]()
    procBody = newStmtList()
    start = 0
  # Если у нас есть `usage = something`
  if body[0].kind == nnkAsgn:
    start = 1
    let text = body[0][1]
    
    # Если это массив, например ["a", "b"]
    if text.kind == nnkBracket:
      for i in 0..<text.len:
        moduleUsages.add text[i].strVal
    # Если это строка, или строка с тройными кавычками
    elif text.kind == nnkStrLit or text.kind == nnkTripleStrLit:
      usage = text.strVal
  # Добавляем сам код обработчика
  for i in start..<body.len:
    procBody.add body[i]
  # Добавляем к usages только если usage - не пустая строка
  if usage.len > 0:
    usages.add usage
  # Если есть строки в moduleUsages
  if moduleUsages.len > 0:
    usage = moduleUsages.join("\n")
    for x in moduleUsages:
      # Добавляем к глобальным usages
      if x != "": usages.add(x)
  # Инкрементируем счётчик для уникальных имён
  inc count
  
  let
    # Создаём идентификационные ноды, чтобы Nim не изменял имя переменных
    api = newIdentNode("api")
    msg = newIdentNode("msg")
    procUsage = newIdentNode("usage")
    args = newIdentNode("args")
    text = newIdentNode("text")
  # Добавляем код к результату
  result = quote do:
    proc `uniqName`(`api`: VkApi, `msg`: Message) {.async.} = 
      # Добавляем "usage" для того, чтобы использовать его внутри процедуры
      const `procUsage` = `usage`
      # Сокращение для "msg.cmd.args"
      let `args` = `msg`.cmd.args
      # Сокращение для получения текста (сразу всех аргументов)
      let `text` = `msg`.cmd.args.join(" ")
      # Вставляем само тело процедуры
      `procBody`
    # Команды, которые обрабатываются этим обработчиком
    const cmds = `cmds`
    # Вызываем proc.handle(cmds) из command.nim
    handle(`uniqName`, cmds)

macro module*(names: varargs[string], body: untyped): untyped = 
  # Добавляем в модули имя нашего модуля (все строки объединённые с пробелом)
  modules.add names.mapIt(it.strVal).join(" ")
  result = body
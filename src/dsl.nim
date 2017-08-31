# Стандартная библиотека
import macros
import strutils
import sequtils
# Свои модули
import utils
import vkapi
import types
import commands
import tables

# Увеличивается с каждым новым обработчиком команды
# Создан для уникальных имён
var count {.compiletime.} = 1

macro command*(cmds: varargs[string], body: untyped): untyped =
  let uniqName = newIdentNode("handler" & $count)
  let uniqNameStr = "handler" & $count
  var 
    usage = newSeq[string]()
    procBody = newStmtList()
    start = 0
  # Если у нас есть `usage = something`
  if body[0].kind == nnkAsgn:
    start = 1
    let text = body[0][1]
    # Если это массив, например ["a", "b"]
    if text.kind == nnkBracket:
      for i in 0..<text.len:
        usage.add text[i].strVal
    # Если это строка, или строка с тройными кавычками
    elif text.kind == nnkStrLit or text.kind == nnkTripleStrLit:
      usage.add text.strVal
  # Добавляем сам код обработчика
  for i in start..<body.len:
    procBody.add body[i]
  # Инкрементируем счётчик для уникальных имён
  inc count
  
  let
    # Создаём идентификационные ноды, чтобы Nim не изменял имя переменных
    api = newIdentNode("api")
    msg = newIdentNode("msg")
    procUsage = newIdentNode("usage")
    args = newIdentNode("args")
    text = newIdentNode("text")
    name = newIdentNode("name")
  # Добавляем код к результату
  var cmdsSeq = newSeq[string]()
  for x in cmds:
    cmdsSeq.add($x)
  result = quote do:
    proc `uniqName`*(`api`: VkApi, `msg`: Message) {.async.} = 
      # Добавляем "usage" для того, чтобы использовать его внутри процедуры
      const `procUsage` = `usage`
      # Сокращение для "msg.cmd.args"
      let `args` = `msg`.cmd.args
      # Сокращение для получения текста (сразу всех аргументов)
      let `text` = `msg`.cmd.args.join(" ")
      # Вставляем само тело процедуры
      `procBody`
    # Команды, которые обрабатываются этим обработчиком
    # const cmds = `cmds`
    static:
      # Получаем имя файла с текущим модулем
      let file = instantiationInfo().filename.split(".nim")[0]
      # Добавляем информацию в последовательность модулей
      compileModules.add((@(`cmdsSeq`), file, `uniqNameStr`))
      # Добавляем все команды в последовательность команд
      for cmd in @(`cmdsSeq`):
        commands.add(cmd)

macro module*(names: varargs[string], body: untyped): untyped = 
  let moduleName = newStrLitNode(names.mapIt($it).join(" "))
  let name = newIdentNode("name")
  result = quote do:
    block:
      const `name` = `moduleName`
    `body`
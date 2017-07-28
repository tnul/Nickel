include baseimports
# Стандартная библиотека
import tables  # Таблицы (для соотношения команд с процедурами-обработчиками)
# Свои модули
import types  # Общие типы бота

var 
  commands* = initTable[string, ModuleFunction]()
  anyCommands*: seq[ModuleFunction] = @[]

proc handle*(handler: ModuleFunction, cmds: varargs[string]) = 
  ## Процедура для добавления нескольких комманд для данного обработчика
  ## Пример - call.handle("привет", "ку"), где call - это ModuleFunction
  for cmd in cmds:
    if cmd == "": anyCommands.add(handler)
    else: commands[cmd] = handler

# Все модули объявляются во время компиляции, 
# поэтому используется {.compiletime.}
var 
  modules* {.compiletime.}: seq[string] = @[]
  usages* {.compiletime.}: seq[string] = @[]

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
  if foundPrefix == nil:
    return
  # Получаем команду и аргументы - берём слайс строки body без префикса,
  # используем strip для удаления нежелательных пробелов в начале и конце,
  # делим строку на имя команды и значения
  let values = body[len(foundPrefix)..^1].strip().split()
  let (name, args) = (values[0], values[1..^1])
  # Возвращаем первое слово из строки в нижнем регистре и аргументы
  return Command(name: unicode.toLower(name), args: args)

{.experimental.}
# Модули стандартной библиотеки
import json  # Обработка JSON
import httpclient  # HTTP запросы
import strutils  # Парсинг строк в числа
import tables  # Для некоторых методов JSON
import os # Операции ОС (открытие файла)

# Модули из Nimble
import strfmt  # используется функция interp

# Свои модули, и модули, которых нет в Nimble
import utils/[unpack, lexim/lexim]  # макрос unpack
import types  # Общие типы бота
import vkapi  # Реализация вк апи

# Импорт плагинов
import plugins/[example, greeting, curtime]



proc getLongPollUrl(bot: var VkBot) =
  ## Получает URL для Long Polling на основе данных LongPolling бота
  let data = bot.lpData
  let url = interp"https://${data.server}?act=a_check&key=${data.key}&ts=${data.ts}&wait=25&mode=2&version=1"
  bot.lpUrl = url

proc processCommand(body: string): Command =
  ## Обрабатывает строку {body} и возвращает тип Command
  let values = body.split()
  return Command(command: values[0], arguments: values[1..values.high()])
  
proc processMessage(bot:VkBot, msg: Message): bool =
  ## Обработать сообщение: пометить его прочитанным, если нужно, передать плагинам...
  let cmdObj = msg.cmd
  case cmdObj.command:
    of "привет":
      greeting.call(bot.api, msg)
    of "время":
      curtime.call(bot.api, msg)
    of "тест":
      example.call(bot.api, msg)
    else:
      discard

proc processLpMessage(bot: VkBot, event: seq[JsonNode]) =
  ## Обрабатывает сырое событие нового сообщения
  # Распаковать значения из события
  event.extract(msgId, flags, peerId, ts, subject, text, attaches)

  # Конвертировать число в set значений Flags
  let msgFlags: set[Flags] = cast[set[Flags]](int(flags.getNum()))

  # Если мы отправили это сообщение - его обрабатывать не нужно
  if Flags.Outbox in msgFlags:
    return
  
  # Обработать строку и создать объект команды
  let cmd = processCommand(text.str.replace("<br>", "\n"))
  # Создаёт объект Message
  let message = Message(
    msgId: int(msgId.getNum()),
    peerId: int(peerId.getNum()),
    timestamp: int(ts.getNum()),
    cmd: cmd,
    attachments: attaches
  )
  discard bot.processMessage(message)

proc initBot(token: string): VkBot =
  ## Возвращает новый объект VkBot на основе токена
  let api = newAPI(token)
  var lpData = LongPollData()
  return VkBot(api: api, lpData: lpData)


proc initLongPolling(bot: var VkBot, failData: JsonNode = %* {}) =
  ## Инициализирует данные для Long Polling сервера (или обрабатывает ошибку) 
  const retries = 5
  var data: JsonNode
  # Пытаемся получить значения Long Polling'а 5 раз
  for retry in 0..retries:
    data = bot.api.callMethod("messages.getLongPollServer", {"use_ssl":"1"})
    if likely(data.getFields.len > 0):
      break
  
  bot.lpData = LongPollData()
  if failData.getElems.len == 0:
    # Нам нужно инициализировать все параметры - первый запуск
    bot.lpData.server = data["server"].str    
    bot.lpData.key = data["key"].str
    bot.lpData.ts = int(data["ts"].getNum())
    bot.getLongPollUrl()
    return
  case int(failData.getNum()):
    of 1:
      ## Обновить метку времени
      bot.lpData.ts = int(failData["ts"].getNum())
    of 2:
      ## Обновить ключ
      bot.lpData.key = data["key"].str
    of 3:
      ## Обновить ключ и метку времени
      bot.lpData.key = data["key"].str
      bot.lpData.ts = int(data["ts"].getNum())
    else:
      discard

  # Обновить URL Long Polling'а
  bot.getLongPollUrl()

# Объявляем mainLoop здесь, чтобы startBot его увидел  
proc mainLoop(bot: var VkBot)

proc startBot(bot: var VkBot) = 
  ## Инициализирует Long Polling и Запускает главный цикл бота
  bot.initLongPolling()
  bot.running = true
  bot.mainLoop()

proc mainLoop(bot: var VkBot) =
  ## Главный цикл бота (тут идёт обработка новых событий)
  while bot.running:
    # Парсим ответ сервера в JSON
    let resp = parseJson(bot.api.http.get(bot.lpUrl).body)
    let events = resp["updates"]
    let failed = resp.getOrDefault("failed")
    # Если у нас есть поле failed - значит произошла какая-то ошибка
    if failed != nil:
      bot.initLongPolling(failed)
    for event in events:
      let elems = event.getElems()
      let (eventType, eventData) = (elems[0].getNum(), elems[1..^1])

      case eventType:
        # Код события 4 - у нас новое сообщение
        of 4:
          bot.processLpMessage(eventData)
        else:
          discard
    # Нам нужно обновить наш URL с новой меткой времени
    bot.lpData.ts = int(resp["ts"].getNum())
    bot.getLongPollUrl()

proc gracefulShutdown() {.noconv.} =
    ## Выключение бота с ожиданием (срабатывает на Ctrl+C)
    echo("Выключение бота...")
    sleep(500)
    quit(0)

when isMainModule:
  echo("Чтение access_token из файла token")
  let token = readLine(open("token", fmRead))
  var bot = initBot(token)
  # Set our hook to Control+C - will be useful in future
  # (close database, end queries etc...)
  setControlCHook(gracefulShutdown)
  echo("Запуск главного цикла бота...")
  bot.startBot()
  
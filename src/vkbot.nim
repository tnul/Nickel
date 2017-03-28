{.experimental.}
# Модули стандартной библиотеки
import json  # Обработка JSON
import httpclient  # HTTP запросы
import strutils  # Парсинг строк в числа
import tables  # Для некоторых методов JSON
import os # Операции ОС (открытие файла)
import asyncdispatch
# Модули из Nimble
import strfmt  # используется функция interp

# Свои модули, и модули, которых нет в Nimble
import utils/unpack  # макрос unpack
import types  # Общие типы бота
import vkapi  # Реализация вк апи

# Импорт плагинов
import plugins/[example, greeting, curtime, joke, sayrandom, shutdown]

proc getLongPollUrl(bot: VkBot) =
  ## Получает URL для Long Polling на основе данных LongPolling бота
  let data = bot.lpData
  let url = interp"https://${data.server}?act=a_check&key=${data.key}&ts=${data.ts}&wait=25&mode=2&version=1"
  bot.lpUrl = url

proc processCommand(body: string): Command =
  ## Обрабатывает строку {body} и возвращает тип Command
  let values = body.split()
  return Command(command: values[0], arguments: values[1..values.high()])
  
proc processMessage(bot:VkBot, msg: Message) {.async.} =
  ## Обработать сообщение: пометить его прочитанным, если нужно, передать плагинам...
  let cmdObj = msg.cmd
  # Смотрим на команду
  case cmdObj.command:
    of "привет":
      await greeting.call(bot.api, msg)
    of "время":
      await curtime.call(bot.api, msg)
    of "тест":
      await example.call(bot.api, msg)
    of "пошути":
      await joke.call(bot.api, msg)
    of "рандом":
      await sayrandom.call(bot.api, msg)
    of "выключись":
      await shutdown.call(bot.api, msg)
    else:
      discard

proc processLpMessage(bot: VkBot, event: seq[JsonNode]) {.async.} =
  ## Обрабатывает сырое событие нового сообщения
  # Распаковываем значения из события
  event.extract(msgId, flags, peerId, ts, subject, text, attaches)

  # Конвертируем число в set значений enum'а Flags
  let msgFlags: set[Flags] = cast[set[Flags]](int(flags.getNum()))

  # Если мы отправили это сообщение - его обрабатывать не нужно
  if Flags.Outbox in msgFlags:
    return
  
  # Обрабатываем строку и создаём объект команды
  let cmd = processCommand(text.str.replace("<br>", "\n"))
  # Создаёт объект Message
  let message = Message(
    msgId: int(msgId.getNum()),
    peerId: int(peerId.getNum()),
    timestamp: int(ts.getNum()),
    subject: subject.str,
    cmd: cmd,
    attachments: attaches
  )
  await bot.processMessage(message)

proc newBot(token: string): VkBot =
  ## Возвращает новый объект VkBot на основе токена
  let api = newApi(token)
  var lpData = LongPollData()
  return VkBot(api: api, lpData: lpData)


proc initLongPolling(bot: VkBot, failData: JsonNode = %* {}) {.async.} =
  ## Инициализирует данные для Long Polling сервера (или обрабатывает ошибку) 
  const retries = 5
  var data: JsonNode
  # Пытаемся получить значения Long Polling'а (5 попыток)
  for retry in 0..retries:
    data = await bot.api.callMethod("messages.getLongPollServer", @[("use_ssl","1")])
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
  # Смотрим на код ошибки
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
proc mainLoop(bot: VkBot) {.async.} 

proc startBot(bot: VkBot) {.async.} = 
  ## Инициализирует Long Polling и Запускает главный цикл бота
  await bot.initLongPolling()
  bot.running = true
  await bot.mainLoop()

proc mainLoop(bot: VkBot) {.async.} =
  ## Главный цикл бота (тут идёт обработка новых событий)
  while bot.running:
    # Парсим ответ сервера в JSON
    let resp = await bot.api.http.get(bot.lpUrl)
    let data = await resp.body
    let jsonData = parseJson(data)
    let events = jsonData["updates"]
    let failed = jsonData.getOrDefault("failed")
    # Если у нас есть поле failed - значит произошла какая-то ошибка
    if failed != nil:
      await bot.initLongPolling(failed)
    for event in events:
      let elems = event.getElems()
      let (eventType, eventData) = (elems[0].getNum(), elems[1..^1])

      case eventType:
        # Код события 4 - у нас новое сообщение
        of 4:
          await bot.processLpMessage(eventData)
        else:
          discard
    # Нам нужно обновить наш URL с новой меткой времени
    bot.lpData.ts = int(jsonData["ts"].getNum())
    bot.getLongPollUrl()

proc gracefulShutdown() {.noconv.} =
    ## Выключение бота с ожиданием (срабатывает на Ctrl+C)
    echo("Выключение бота...")
    sleep(500)
    quit(0)

when isMainModule:
  echo("Чтение access_token из файла token")
  let token = readLine(open("token", fmRead))
  var bot = newBot(token)
  # Set our hook to Control+C - will be useful in future
  # (close database, end queries etc...)
  setControlCHook(gracefulShutdown)
  echo("Запуск главного цикла бота...")
  asyncCheck bot.startBot()
  runForever()
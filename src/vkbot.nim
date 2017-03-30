{.experimental.}
# Модули стандартной библиотеки
import json  # Обработка JSON
import httpclient  # HTTP запросы
import strutils  # Парсинг строк в числа
import strtabs  # Для некоторых методов JSON
import os  # Операции ОС (открытие файла)
import asyncdispatch  # Асинхронщина
import unicode  # операции с юникодными строками

# Модули из Nimble
import strfmt  # используется функция interp

# Свои модули, и модули, которых нет в Nimble
import utils  # Макрос unpack (взят со stackoverflow)
import types  # Общие типы бота
import vkapi  # Реализация VK API
import parsecfg # Парсинг файла конфигурации

import termcolor  # Цвета в консоли

# Импорт плагинов
import plugins/[example, greeting, curtime, joke, 
                sayrandom, shutdown, currency, dvach, notepad, soothsayer]


const Commands = ["привет", "тест", "время", "пошути", "рандом", "выключись",
                  "курс","мемы", "двач", "блокнот", "шар"]


proc parseConfig(path: string): BotConfig = 
  try:
    let data = loadConfig(path)
    return BotConfig(
      token: data.getSectionValue("Авторизация", "токен"),
      logMessages: data.getSectionValue("Бот", "сообщения").parseBool(),
      logCommands: data.getSectionValue("Бот", "команды").parseBool(),
      reportErrors: data.getSectionValue("Ошибки", "ошибки").parseBool(),
      fullReport: data.getSectionValue("Ошибки", "полные_ошибки").parseBool(),
      logErrors: data.getSectionValue("Ошибки", "лог_ошибок").parseBool(),
      errorMessage: data.getSectionValue("Сообщения", "ошибка")
    )
  except:
    echo("Не удалось загрузить конфигурацию, проверьте файл settings.ini!")
    quit(1)

proc log(config: BotConfig) = 
  echo("Логгировать сообщения - " & $config.logMessages)
  echo("Логгировать команды - " & $config.logCommands)
  echo("Сообщение при ошибке - " & $config.errorMessage)
  echo("Отправлять ошибки пользователям - " & $config.reportErrors)
  echo("Выводить ошибки в консоль - " & $config.logErrors)
  echo("Отправлять полный лог ошибки пользователям - " & $config.fullReport)

proc getLongPollUrl(bot: VkBot) =
  ## Получает URL для Long Polling на основе данных LongPolling бота
  let data = bot.lpData
  let url = interp"https://${data.server}?act=a_check&key=${data.key}&ts=${data.ts}&wait=25&mode=2&version=1"
  bot.lpUrl = url

proc processCommand(body: string): Command =
  ## Обрабатывает строку {body} и возвращает тип Command
  let values = body.split()
  return Command(command: unicode.toLower(values[0]), arguments: values[1..^1])
  
proc processMessage(bot:VkBot, msg: Message) {.async.} =
  ## Обрабатывает сообщение: обозначает его прочитанным, 
  ## передаёт события плагинам...
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
    of "курс":
      await currency.call(bot.api, msg)
    of "двач":
      await dvach.call(bot.api, msg, true)
    of "мемы":
      await dvach.call(bot.api, msg)
    of "блокнот":
      await notepad.call(bot.api, msg)
    of "шар":
      await soothsayer.call(bot.api, msg)
    else:
      discard

proc processLpMessage(bot: VkBot, event: seq[JsonNode]) {.async.} =
  ## Обрабатывает сырое событие нового сообщения
  # Распаковываем значения из события
  event.extract(msgId, flags, peerId, ts, subject, text, attaches)

  # Конвертируем число в set значений enum'а Flags
  let msgFlags: set[Flags] = cast[set[Flags]](int(flags.getNum()))

  # Если мы же и отправили это сообщение - его обрабатывать не нужно
  if Flags.Outbox in msgFlags:
    return
  let msgPeerId = int(peerId.getNum())
  let msgBody = text.str.replace("<br>", "\n")
  # Обрабатываем строку и создаём объект команды
  let cmd = processCommand(msgBody)
  # Создаём объект Message
  let message = Message(
    msgId: int(msgId.getNum()),
    peerId: msgPeerId,
    timestamp: int(ts.getNum()),
    subject: subject.str,
    cmd: cmd,
    body: text.str, 
    attachments: attaches
  )
  if bot.config.logCommands and cmd.command in Commands:
    message.log(command = true)
  elif bot.config.logMessages:
    message.log(command = false)
  
  # Выполняем обработку сообщения
  let result = bot.processMessage(message)
  yield result
  # Если обработка сообщения (или один из плагинов) вызвали ошибку
  if unlikely(result.failed):
    let rnd = antiFlood() & "\n"
    let err = repr(getCurrentException())
    var errorMessage = rnd & bot.config.errorMessage
    if bot.config.fullReport:
      # Если нужно, добавляем полный лог ошибки
      errorMessage &= "\n" & err & "\n" & getCurrentExceptionMsg()
    if bot.config.logErrors:
      # Если нужно писать ошибки в консоль
      coloredLog(termcolor.Error, err & "\n" & getCurrentExceptionMsg())
    # Отправляем ошибку
    await bot.api.answer(message, errorMessage)

proc newBot(config: BotConfig): VkBot =
  ## Возвращает новый объект VkBot на основе токена
  let api = newApi(config.token)
  var lpData = LongPollData()
  return VkBot(api: api, lpData: lpData, config: config)

proc initLongPolling(bot: VkBot, failData: JsonNode = %* {}) {.async.} =
  ## Инициализирует данные для Long Polling сервера (или обрабатывает ошибку) 
  const MaxRetries = 5  # Максимальнок кол-во попыток для лонг пуллинга
  var data: JsonNode
  # Пытаемся получить значения Long Polling'а (5 попыток)
  for retry in 0..MaxRetries:
    let params = {"use_ssl":"1"}.api
    data = await bot.api.callMethod("messages.getLongPollServer", params)
    # Если есть какие-то объекты в data, выходим из цикла
    if likely(data.len() > 0):
      break
    
  # Создаём новый объект Long Polling'а
  bot.lpData = LongPollData()
  if unlikely(failData.getElems.len == 0):
    # Нам нужно инициализировать все параметры - первый запуск
    bot.lpData.server = data["server"].str    
    bot.lpData.key = data["key"].str
    bot.lpData.ts = int(data["ts"].getNum())
    bot.getLongPollUrl()
    return
  
  # Смотрим на код ошибки
  case int(failData.getNum()):
    of 1:
      ## Обновляем метку времени
      bot.lpData.ts = int(failData["ts"].getNum())
    of 2:
      ## Обновляем ключ
      bot.lpData.key = data["key"].str
    of 3:
      ## Обновляем ключ и метку времени
      bot.lpData.key = data["key"].str
      bot.lpData.ts = int(data["ts"].getNum())
    else:
      discard

  # Обновляем URL Long Polling'а
  bot.getLongPollUrl()

proc mainLoop(bot: VkBot) {.async.} =
  ## Главный цикл бота (тут происходит получение новых событий)
  while bot.running:
    var resp: AsyncResponse
    try:
      resp = await bot.api.http.get(bot.lpUrl)
    except:
      # Какая-то ошибка с получением запроса
      continue
    let 
      data = await resp.body
      # Парсим ответ сервера в JSON
      jsonData = parseJson(data)
      failed = jsonData.getOrDefault("failed")
    
    # Если у нас есть поле failed - значит произошла какая-то ошибка
    if unlikely(failed != nil):
      await bot.initLongPolling(failed)
      continue
    let events = jsonData["updates"]  
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

proc startBot(bot: VkBot) {.async.} = 
  ## Инициализирует Long Polling и запускает главный цикл бота
  await bot.initLongPolling()
  bot.running = true
  await bot.mainLoop()

proc gracefulShutdown() {.noconv.} =
  ## Выключает бота с ожиданием 500мс (срабатывает на Ctrl+C)
  echo("Выключение бота...")
  sleep(500)
  quit(0)

when isMainModule:
  echo("Загрузка настроек из settings.ini...")
  let config = parseConfig("settings.ini")
  # Выводим значения конфига (кроме токена)
  config.log()
  var bot = newBot(config)
  # Set our hook to Control+C - will be useful in future
  # (close database, end queries etc...)
  setControlCHook(gracefulShutdown)
  echo("Запуск главного цикла бота...")
  asyncCheck bot.startBot()
  asyncdispatch.runForever()

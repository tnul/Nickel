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
import config # Парсинг файла конфигурации
import errors  # Обработка ошибок
import termcolor  # Цвета в консоли

# Импорт плагинов
import plugins/[example, greeting, curtime, joke, 
                sayrandom, shutdown, currency, dvach, notepad, 
                soothsayer, everypixel]


const Commands = ["привет", "тест", "время", "пошути", "рандом", "выключись",
                  "курс","мемы", "двач", "блокнот", "шар", "оцени"]




proc getLongPollUrl(bot: VkBot) =
  ## Получает URL для Long Polling на основе данных LongPolling бота
  let 
    data = bot.lpData
    url = interp"https://${data.server}?act=a_check&key=${data.key}&ts=${data.ts}&wait=25&mode=2&version=1"
  bot.lpUrl = url

proc processCommand(body: string): Command =
  ## Обрабатывает строку {body} и возвращает тип Command
  # Если тело сообщения пустое
  if len(body) == 0:
    return
  # Делим тело сообщения на части
  let values = body.split()
  return Command(command: unicode.toLower(values[0]), arguments: values[1..^1])

proc processMessage(bot: VkBot, msg: Message) {.async.} =
  ## Обрабатывает сообщение: обозначает его прочитанным, 
  ## передаёт события плагинам...
  let cmdObj = msg.cmd
  # Смотрим на команду
  case cmdObj.command:
    of "привет":
      runCatch(greeting.call, bot, msg)
    of "время":
      runCatch(curtime.call, bot, msg)
    of "тест":
      runCatch(example.call, bot, msg)
    of "пошути":
      runCatch(joke.call, bot, msg)
    of "рандом":
      runCatch(sayrandom.call, bot, msg)
    of "выключись":
      runCatch(shutdown.call, bot, msg)
    of "курс":
      runCatch(currency.call, bot, msg)
    of "двач", "мемы":
      runCatch(dvach.call, bot, msg)
    of "блокнот":
      runCatch(notepad.call, bot, msg)
    of "шар":
      runCatch(soothsayer.call, bot, msg)
    of "оцени":
      runCatch(everypixel.call, bot, msg)
    else:
      discard

proc processAttaches(attaches: JsonNode): seq[Attachment] = 
  ## Функция, обрабатывающая приложения  к сообщению
  result = @[]
  for key, value in pairs(attaches):
    # Если эта пара значений - не указание типа аттача
    if not("_type" in key):
      # Если для такого аттача нет указания типа, пропускаем
      if not(key & "_type" in attaches):
        continue
      # Тип аттача
      let attachType = attaches[key & "_type"].str
      # Owner ID и ID самого аттача
      let data = value.str.split("_")
      if not len(data) > 1:
        continue
      # ID владельца и ID самого аттачмента
      var owner_id, atch_id: string
      try:
        (owner_id, atch_id) = (data[0], data[1])
      except IndexError:
        # С некоторыми видами аттачей это случается
        continue
      result.add((attachType, owner_id, atch_id))
    
proc processLpMessage(bot: VkBot, event: seq[JsonNode]) {.async.} =
  ## Обрабатывает сырое событие нового сообщения
  # Распаковываем значения из события
  event.extract(msgId, flags, peerId, ts, subject, text, attaches)

  # Конвертируем число в set значений enum'а Flags
  let msgFlags: set[Flags] = cast[set[Flags]](int(flags.getNum()))
  # Если мы же и отправили это сообщение - его обрабатывать не нужно
  if Flags.Outbox in msgFlags:
    return
  
  let 
    msgPeerId = int(peerId.getNum())
    msgBody = text.str.replace("<br>", "\n")
    # Обрабатываем строку и создаём объект команды
    cmd = processCommand(msgBody)
    # Создаём объект Message
    message = Message(
      id: int(msgId.getNum()),
      pid: msgPeerId,
      timestamp: int(ts.getNum()),
      subject: subject.str,
      cmd: cmd,
      body: text.str, 
      attaches: processAttaches(attaches)
    )
  if bot.config.logCommands and cmd.command in Commands:
    message.log(command = true)
  elif bot.config.logMessages:
    message.log(command = false)
  
  # Выполняем обработку сообщения
  let processResult = bot.processMessage(message)
  yield processResult
  # Если обработка сообщения (или один из плагинов) вызвали ошибку
  if unlikely(processResult.failed):
    let 
      # Случайные буквы
      rnd = antiFlood() & "\n"
      # Ошибка 
    # Сообщение, котороые мы пошлём
    var errorMessage = rnd & bot.config.errorMessage & "\n"
    if bot.config.fullReport:
      # Если нужно, добавляем полный лог ошибки
      errorMessage &= "\n" & getCurrentExceptionMsg()
    if bot.config.logErrors:
      # Если нужно писать ошибки в консоль
      log(termcolor.Error, "\n" & getCurrentExceptionMsg())
    # Отправляем сообщение об ошибке
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
  let http = newAsyncHttpClient()
  while bot.running:
    let resp = http.get(bot.lpUrl)
    yield resp
    if resp.failed:
      continue
    let data = await resp.read().body
    let 
      # Парсим ответ сервера в JSON
      jsonData = parseJson(data)
      failed = jsonData.getOrDefault("failed")
    
    # Если у нас есть поле failed - значит произошла какая-то ошибка
    if unlikely(failed != nil):
      await bot.initLongPolling(failed)
      continue
    let events = jsonData["updates"]  
    for event in events:
      let 
        elems = event.getElems()
        (eventType, eventData) = (elems[0].getNum(), elems[1..^1])

      case eventType:
        # Код события 4 - у нас новое сообщение
        of 4:
          asyncCheck bot.processLpMessage(eventData)
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
  log(termcolor.Hint, "Выключение бота...")
  sleep(500)
  quit(0)

when isMainModule:
  let cfg = parseConfig()
  # Выводим значения конфига (кроме токена)
  cfg.log()
  var bot = newBot(cfg)
  # Set our hook to Control+C - will be useful in future
  # (close database, end queries etc...)
  setControlCHook(gracefulShutdown)
  log(termcolor.Warning, "Запуск главного цикла бота...")
  asyncCheck bot.startBot()
  asyncdispatch.runForever()

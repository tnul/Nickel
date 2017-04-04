{.experimental.}
# Модули стандартной библиотеки
import json  # Обработка JSON
import httpclient  # HTTP запросы
import strutils  # Парсинг строк в числа
import strtabs  # Для некоторых методов JSON
import os  # Операции ОС (открытие файла)
import asyncdispatch  # Асинхронщина
import unicode  # операции с юникодными строками
import tables  # для работы с command

# Модули из Nimble
import strfmt  # используется функция interp

# Свои модули, и модули, которых нет в Nimble
import utils  # Макрос unpack (взят со stackoverflow)
import types  # Общие типы бота
import vkapi  # Реализация VK API
import config # Парсинг файла конфигурации
import errors  # Обработка ошибок
import termcolor  # Цвета в консоли
import command  # таблица {команда: плагин} и макросы
# Импорт плагинов
import plugins/[example, greeting, curtime, joke, 
                sayrandom, shutdown, currency, dvach, notepad, 
                soothsayer, everypixel]


const Commands = ["привет", "тест", "время", "пошути", "рандом", "выключись",
                  "курс","мемы", "двач", "блокнот", "шар", "оцени"]


# Переменная для обозначения, работает ли главный цикл бота

var running = false
proc getLongPollUrl(bot: VkBot) =
  ## Получает URL для Long Polling на основе данных, полученных ботом
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
  # Возвращаем первое слово из строки в нижнем регистре и аргументы
  return Command(command: unicode.toLower(values[0]), arguments: values[1..^1])

proc processMessage(bot: VkBot, msg: Message) {.async.} =
  ## Обрабатывает сообщение: логгирует, передаёт события плагинам
  let cmdText = msg.cmd.command
  # Если в таблице команд есть эта команда
  if commands.contains(cmdText):
    # Если нужно логгировать команды
    if bot.config.logCommands:
      msg.log(command = true)
    # Получаем процедуру плагина, которая обрабатывает эту команду
    let handler = commands[cmdText]
    # Выполняем процедуру асинхронно с хэндлером ошибок
    runCatch(handler, bot, msg)
  else:
    # Если это не команда, и нужно логгировать сообщения
    if bot.config.logMessages:
      msg.log(command = false)

proc processAttaches(attaches: JsonNode): seq[Attachment] = 
  ## Функция, обрабатывающая приложения к сообщению
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
  
  # Выполняем обработку сообщения
  let processResult = bot.processMessage(message)
  yield processResult
  # Если обработка сообщения вызвала ошибку
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
  ## Инициализирует данные или обрабатывает ошибку Long Polling сервера
  const MaxRetries = 5  # Максимальнок кол-во попыток для запроса лонг пуллинга
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
  running = true
  let http = newAsyncHttpClient()
  while running:
    # Получаем ответ от сервера ВК
    let resp = http.get(bot.lpUrl)
    yield resp
    # Если не удалось получить, делаем следующий цикл
    if resp.failed:
      continue
    let 
      # Читаем тело ответа
      data = await resp.read().body
      # Парсим ответ сервера в JSON
      jsonData = parseJson(data)
      failed = jsonData.getOrDefault("failed")
    
    # Если у нас есть поле failed - значит произошла какая-то ошибка
    if unlikely(failed != nil):
      await bot.initLongPolling(failed)
      continue

    let events = jsonData["updates"]
    for event in events:
      # Делим каждое событие на его тип, и на информацию о нём
      let 
        elems = event.getElems()
        (eventType, eventData) = (elems[0].getNum(), elems[1..^1])

      case eventType:
        # Код события 4 - у нас новое сообщение
        of 4:
          asyncCheck bot.processLpMessage(eventData)
        # Другие события нам пока что не нужны :)
        else:
          discard
          
    # Обновляем метку времени
    bot.lpData.ts = int(jsonData["ts"].getNum())
    # Получаем новый URL для лонг пуллинга
    bot.getLongPollUrl()

proc startBot(bot: VkBot) {.async.} = 
  ## Инициализирует Long Polling и запускает главный цикл бота
  await bot.initLongPolling()
  await bot.mainLoop()

proc gracefulShutdown() {.noconv.} =
  ## Выключает бота с ожиданием 500мс (срабатывает на Ctrl+C)
  log(termcolor.Hint, "Выключение бота...")
  running = false
  sleep(500)
  quit(0)

when isMainModule:
  let cfg = parseConfig()
  # Выводим значения конфига (кроме токена)
  cfg.log()
  # Создаём новый объект бота на основе конфигурации
  var bot = newBot(cfg)
  # Устанавливаем хук на Ctrl+C, пока что бесполезен, но
  # может пригодиться в будущем (закрывать сессии к БД и т.д)
  setControlCHook(gracefulShutdown)
  logWithStyle(termcolor.Success):
    ("Общее количество команд - " & $len(commands))
    ("Бот успешно запущен и ожидает команд...")
    
  asyncCheck bot.startBot()
  asyncdispatch.runForever()

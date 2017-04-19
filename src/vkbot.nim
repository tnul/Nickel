{.experimental.}
include baseimports

# Свои модули, и модули, которых нет в Nimble
import utils  # Макрос unpack (взят со stackoverflow)
import types  # Общие типы бота
import vkapi  # Реализация VK API
import config # Парсинг файла конфигурации
import errors  # Обработка ошибок
import command  # таблица {команда: плагин} и макросы
import log  # логгирование
# Импорт плагинов
import plugins/[example, greeting, curtime, joke,
                sayrandom, shutdown, currency, dvach, notepad,
                soothsayer, everypixel, calc]

# Переменная для обозначения, работает ли главный цикл бота
var running = false

proc getLongPollUrl(bot: VkBot) =
  ## Получает URL для Long Polling на основе данных, полученных ботом
  const WaitTime = 20
  let
    data = bot.lpData
    url = interp"https://${data.server}?act=a_check&key=${data.key}&ts=${data.ts}&wait=${WaitTime}&mode=2&version=1"
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
    # Неожиданно, но ВК посылает Long Polling с <br>'ами вместо \n
    msgBody = text.str.replace("<br>", "\n")
    # Обрабатываем строку и создаём объект команды
    cmd = processCommand(msgBody)
    # Создаём объект Message
    message = Message(
      id: int(msgId.getNum()),  # ID сообщения
      pid: msgPeerId,  # ID отправителя
      timestamp: int(ts.getNum()),  # Когда было отправлено сообщение
      subject: subject.str,  # Тема сообщения
      cmd: cmd,  # Объект сообщения
      body: text.str,  # Тело сообщения
    )

  # Выполняем обработку сообщения
  let processResult = bot.processMessage(message)
  yield processResult
  # Если обработка сообщения вызвала ошибку
  if unlikely(processResult.failed):
    let
      # Случайные буквы
      rnd = antiFlood() & "\n"
    # Сообщение, котороые мы пошлём
    var errorMessage = rnd & bot.config.errorMessage & "\n"
    if bot.config.fullReport:
      # Если нужно, добавляем полный лог ошибки
      errorMessage &= "\n" & getCurrentExceptionMsg()
    if bot.config.logErrors:
      # Если нужно писать ошибки в консоль
      logError("\n" & getCurrentExceptionMsg())
    # Отправляем сообщение об ошибке
    await bot.api.answer(message, errorMessage)

proc newBot(config: BotConfig): VkBot =
  ## Возвращает новый объект VkBot на основе токена
  let
    api = newApi(config.token)
    lpData = LongPollData()
  return VkBot(api: api, lpData: lpData, config: config)

proc initLongPolling(bot: VkBot, failNum = 0) {.async.} =
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



  # Смотрим на код ошибки
  case int(failNum)
    # Первый запуск бота
    of 0:
      # Создаём новый объект Long Polling'а
      bot.lpData = LongPollData()
      # Нам нужно инициализировать все параметры - первый запуск
      bot.lpData.server = data["server"].str
      bot.lpData.key = data["key"].str
      bot.lpData.ts = int(data["ts"].getNum())
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
    let request = http.postContent(bot.lpUrl)
    yield request
    if request.failed:
      await sleepAsync(200)
      continue
    let
      # Парсим ответ сервера в JSON

      jsonData = parseJson(request.read())
      failed = jsonData.getOrDefault("failed")
    # Если у нас есть поле failed - значит произошла какая-то ошибка
    if unlikely(failed != nil):
      let failNum = int(failed.getNum())
      if failNum == 1:
        bot.lpData.ts = int(jsonData["ts"].getNum())
      else:
        await bot.initLongPolling(failNum)
      continue

    let events = jsonData["updates"]
    for event in events:
      # Делим каждое событие на его тип и на информацию о нём
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
  logHint("Выключение бота...")
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
  logWithStyle(Success):
    ("Общее количество команд - " & $len(commands))
    ("Бот успешно запущен и ожидает новых команд!")

  asyncCheck bot.startBot()
  # Запускаем бесконечный асинхронный цикл (пока не будет нажата Ctrl+C)
  asyncdispatch.runForever()

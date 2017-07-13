include baseimports
import sequtils  # Работа с последовательностями
# Свои модули
import utils  # Макрос unpack (взят со stackoverflow)
import types  # Общие типы бота
import vkapi  # Реализация VK API
import config # Парсинг файла конфигурации
import errors  # Обработка ошибок
import command  # Таблица {команда: плагин} и макросы
import log  # Логгирование
importPlugins()  # Импортируем все модули из папки modules

# Переменная для обозначения, работает ли главный цикл бота
var running = false

proc getLongPollUrl(bot: VkBot) =
  ## Получает URL для Long Polling на основе данных bot.lpData
  const 
    UrlFormat = "https://$1?act=a_check&key=$2&ts=$3&wait=25&mode=2&version=1"
  let data = bot.lpData
  bot.lpUrl = UrlFormat % [data.server, data.key, $data.ts]

proc processCommand(bot: VkBot, body: string): Command =
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

var 
  msgCount* = 0
  cmdCount* = 0

proc processMessage(bot: VkBot, msg: Message) {.async.} =
  ## Обрабатывает сообщение: логгирует, передаёт события плагинам
  let 
    cmdText = msg.cmd.name
    rusConverted = toRus(cmdText)
    engConverted = toEng(cmdText)
  var command = false
  # Увеличиваем счётчик сообщений
  inc msgCount
  when defined(gui):
    msgCountLabel.text = "Принято сообщений: " & $msgCount
  # TODO: Уменьшить повторение кода в обработке раскладки
  if commands.contains(cmdText):
    command = true

  elif commands.contains(rusConverted):
    msg.cmd.name = rusConverted
    msg.cmd.args.applyIt it.toRus()
    command = true

  elif commands.contains(engConverted):
    msg.cmd.name = engConverted
    msg.cmd.args.applyIt it.toEng()
    command = true
  # Если это команда
  if command:
    # Увеличиваем счётчик команд
    inc cmdCount
    when defined(gui):
      cmdCountLabel.text = "Обработано команд: " & $cmdCount
    # Если нужно логгировать команды
    if bot.config.logCommands:
      msg.log(command = true)
    # Выполняем процедуру модуля асинхронно с хэндлером ошибок
    runCatch(commands[msg.cmd.name], bot, msg)
  else:
    # Если это не команда, и нужно логгировать сообщения
    if bot.config.logMessages:
      msg.log()


proc processLpMessage(bot: VkBot, event: seq[JsonNode]) {.async.} =
  ## Обрабатывает сырое событие нового сообщения
  # Распаковываем значения из события
  event.extract(msgId, flags, peerId, ts, subject, text, attaches)

  # Конвертируем число в set значений enum'а Flags
  let msgFlags = cast[set[Flags]](flags.num)
  # Если мы же и отправили это сообщение - его обрабатывать не нужно
  if Flags.Outbox in msgFlags:
    return

  let
    # ВК посылает Long Polling с <br>'ами вместо \n
    msgBody = text.str.replace("<br>", "\n")
    # Обрабатываем строку и создаём объект команды
    cmd = bot.processCommand(msgBody)
    # Создаём объект Message
    message = Message(
      # Тип сообщения - если есть поле "from" - беседа, иначе - ЛС
      kind: if attaches.contains("from"): msgConf else: msgPriv,
      id: int msgId.num,  # ID сообщения
      pid: int peerId.num,  # ID отправителя
      timestamp: ts.num,  # Когда было отправлено сообщение
      subject: subject.str,  # Тема сообщения
      cmd: cmd,  # Объект сообщения 
      body: text.str,  # Тело сообщения
    )
  # Если это конференция, то добавляем ID пользователя, который
  # отправил это сообщение
  if message.kind == msgConf:
    message.cid = int attaches["from"].num

  # Выполняем обработку сообщения
  let processResult = bot.processMessage(message)
  yield processResult
  # Если сообщение не удалось обработать
  if processResult.failed:
    let rnd = antiFlood() & "\n"
    # Сообщение, котороые мы пошлём
    var errorMessage = rnd & bot.config.errorMessage & "\n"
    if bot.config.fullReport:
      # Если нужно, добавляем полный лог ошибки
      errorMessage &= "\n" & getCurrentExceptionMsg()
    if bot.config.logErrors:
      # Если нужно писать ошибки в консоль
      error("\n" & getCurrentExceptionMsg())
    # Отправляем сообщение об ошибке
    await bot.api.answer(message, errorMessage)

proc newBot(config: BotConfig): VkBot =
  ## Возвращает новый объект VkBot на основе токена
  let
    api = newApi(config)
    lpData = LongPollData()
    isGroup = config.token.len > 0
  # Запускаем бесконечный цикл отправки запросов через execute
  asyncCheck api.executeCaller()
  return VkBot(api: api, lpData: lpData, config: config, isGroup: isGroup)


proc getLongPollApi(api: VkApi): Future[JsonNode] {.async.} = 
  ## Возвращает значения Long Polling от VK API
  const MaxRetries = 5  # Максимальнок кол-во попыток для запроса лонг пуллинга
  let params = {"use_ssl":"1"}.toApi
  # Пытаемся получить значения Long Polling'а (5 попыток)
  for retry in 0..MaxRetries:
    result = await api.callMethod("messages.getLongPollServer", params)
    # Если есть какие-то объекты в data, выходим из цикла
    if result.len > 0:
      break


proc initLongPolling(bot: VkBot, failNum = 0) {.async.} =
  ## Инициализирует данные или обрабатывает ошибку Long Polling сервера
  let data = await bot.api.getLongPollApi()
  case int(failNum)
    # Первый запуск бота
    of 0:
      # Создаём новый объект Long Polling'а
      bot.lpData = LongPollData()
      # Нам нужно инициализировать все параметры - первый запуск
      bot.lpData.server = data["server"].str
      bot.lpData.key = data["key"].str
      bot.lpData.ts = data["ts"].num
    of 2:
      ## Обновляем ключ
      bot.lpData.key = data["key"].str
    of 3:
      ## Обновляем ключ и метку времени
      bot.lpData.key = data["key"].str
      bot.lpData.ts = data["ts"].num
    else:
      discard
  # Обновляем URL Long Polling'а
  bot.getLongPollUrl()

proc mainLoop(bot: VkBot) {.async.} = 
  ## Главный цикл бота (тут происходит получение новых событий)
  running = true
  var http = newAsyncHttpClient()
  while running:
    # Получаем новый URL для лонг пуллинга
    bot.getLongPollUrl()
    # Создаём запрос
    let req = http.getContent(bot.lpUrl)
    # Отправляем его
    yield req
    # Если произошла ошибка
    if req.failed:
      debug("Запрос к LP не удался, создаю новый объект HTTP клиента...")
      #[Из-за бага стандартной библиотеки, если иметь 1 http клиент, он
      крашится через 20-30 минут работы, поэтому мы инициализируем новый
      клиент при каждой ошибке. Но это не ухудшает
      производительность, так как newAsyncHttpClient() можно вызывать
      примерно миллион раз в секунду, а мы его вызываем раз в 10-25 минут]#
      http = newAsyncHttpClient()
      continue
    let
      # Парсим ответ сервера в JSON
      jsonData = parseJson(req.read)
      # Получаем поле failed (если его нет, получаем nil)
      failed = jsonData.getOrDefault("failed")
    # Если у нас есть поле failed - значит произошла какая-то ошибка
    if failed != nil:
      let failNum = int failed.num
      if failNum == 1:
        bot.lpData.ts = jsonData["ts"].num
      else:
        await bot.initLongPolling(failNum)
      continue
    # Такое может случиться (если поля updates нет вообще)
    if not jsonData.contains("updates"): continue
    for event in jsonData["updates"]:
      # Делим каждое событие на его тип и на информацию о нём
      let
        elems = event.elems
        (eventType, eventData) = (elems[0].num, elems[1..^1])

      case eventType:
        # Код события 4 - у нас новое сообщение
        of 4:
          asyncCheck bot.processLpMessage(eventData)
        # Другие события нам пока что не нужны :)
        else:
          discard
    # Обновляем метку времени
    bot.lpData.ts = jsonData["ts"].num
    

proc getNameAndAvatar(bot: VkBot) {.async.} = 
  
  let 
    methodName = if bot.config.token.len > 0: "groups.getById" else: "users.get"
    params = {"fields": "photo_50"}.toApi
    # Получаем информацию о текущем пользователе (и берём первый элемент)
    data = (await bot.api.callMethod(methodName, params, execute = false))[0]
    client = newAsyncHttpClient()
  # Скачиваем аватар
  await client.downloadFile(data["photo_50"].str, "avatar.png")
  # Создаём новую картинку в GUI и загружаем аватар
  var name: string
  if bot.isGroup: 
    name = "Группа " & data["name"].str 
  else: 
    name = "Пользователь " & data["first_name"].str & " " & data["last_name"].str
  var avatar = newImage()
  avatar.loadFromFile("avatar.png")

  # Добавляем картинку в прорисовку
  avatarControl.onDraw = proc (event: DrawEvent) = 
    let canv = event.control.canvas
    canv.drawImage(avatar, 0, 0)
  # Изменяем текст в GUI
  loggedAs.text = name

proc startBot(bot: VkBot) {.async.} =
  ## Инициализирует Long Polling и запускает главный цикл бота
  when defined(gui):
    await bot.getNameAndAvatar()
  await bot.initLongPolling()
  await bot.mainLoop()

proc gracefulShutdown() {.noconv.} =
  ## Выключает бота с ожиданием 500мс (срабатывает на Ctrl+C)
  notice("Выключение бота...")
  running = false
  sleep(500)
  quit(0)

when isMainModule:
  when defined(windows) and not defined(gui):
     # Если мы на Windows - устанавливаем кодировку UTF-8 при запуске бота
    discard execShellCmd("chcp 65001")
    # И очищаем консоль
    discard execShellCmd("cls")
  # Парсим конфиг
  let cfg = parseConfig()
  # Выводим его значения (кроме логина, пароля, и токена)
  cfg.log()
  # Создаём новый объект бота на основе конфигурации
  let bot = newBot(cfg)
  # Устанавливаем хук на Ctrl+C, пока что бесполезен, но
  # может пригодиться в будущем (закрывать сессии к БД и т.д)
  setControlCHook(gracefulShutdown)
  logWithLevel(lvlInfo):
    ("Общее количество загруженных команд - " & $len(commands))
    ("Бот успешно запущен и ожидает новых команд!")
  asyncCheck bot.startBot()
  # Запускаем бесконечный асинхронный цикл (пока не будет нажата Ctrl+C)
  when defined(gui):
    app.run()
  # Запускаем GUI
  else:
    runForever()
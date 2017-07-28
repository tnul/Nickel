include baseimports

# Свои модули
import command  # Обработка команд
import message  # Обработка сообщения
import vkapi  # VK API
import utils  # Утилиты


proc getLongPollUrl(bot: VkBot) =
  ## Получает URL для Long Polling на основе данных bot.lpData
  const 
    UrlFormat = "https://$1?act=a_check&key=$2&ts=$3&wait=25&mode=2&version=1"
  let data = bot.lpData
  bot.lpUrl = UrlFormat % [data.server, data.key, $data.ts]

proc getLongPollApi(api: VkApi): Future[JsonNode] {.async.} = 
  ## Возвращает значения Long Polling от VK API
  const MaxRetries = 5  # Максимальнок кол-во попыток для запроса лонг пуллинга
  let params = {"use_ssl":"1"}.toApi
  # Пытаемся получить значения Long Polling'а (5 попыток)
  for retry in 0..MaxRetries:
    result = await api.callMethod("messages.getLongPollServer", 
                                  params, execute = false)
    # Если есть какие-то объекты в data, выходим из цикла
    if result.len > 0:
      break

proc initLongPolling*(bot: VkBot, failNum = 0) {.async.} =
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
  var fwdMessages = newSeq[ForwardedMessage]()
  # Если есть пересланные сообщения
  if "fwd" in attaches:
    for fwdMsg in attaches["fwd"].str.split(","):
      let data = fwdMsg.split("_")
      fwdMessages.add ForwardedMessage(msgId: data[1])
  # Создаём объект Message
  let message = Message(
      # Тип сообщения - если есть поле "from" - беседа, иначе - ЛС
      kind: if attaches.contains("from"): msgConf else: msgPriv,
      id: int msgId.num,  # ID сообщения
      pid: int peerId.num,  # ID отправителя
      timestamp: ts.num,  # Когда было отправлено сообщение
      subject: subject.str,  # Тема сообщения
      cmd: cmd,  # Объект команды 
      body: text.str,  # Тело сообщения
      fwdMessages: fwdMessages  # Пересланные сообщения
    )
  # Если это конференция, то добавляем ID пользователя, который
  # отправил это сообщение
  if message.kind == msgConf:
    message.cid = int attaches["from"].num

  asyncCheck bot.checkMessage(message)
  
proc mainLoop*(bot: VkBot) {.async.} = 
  ## Главный цикл Long Polling (тут происходит получение новых событий)
  var http = newAsyncHttpClient()
  while true:
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
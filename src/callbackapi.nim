include baseimports
# Стандартная библиотека
import asynchttpserver  # Асинхронный HTTP сервер

# Свои модули
import command  # Обработка команд
import message  # Обработка сообщения
import vkapi  # VK API
import utils  # Утилиты

var
  server = newAsyncHttpServer()
  bot: VkBot

proc processCallbackData(data: JsonNode) {.async.} = 
  ## Обрабатывает событие от Callback API
  # Получаем объект данного события
  let obj = data["object"]
  # Проверяем тип события
  case data["type"].str
  # Новое сообщение
  of "message_new":
    # Тело сообщения
    let msgBody = obj["body"].str
    # Собираем user_id пересланных сообщений (если они есть)
    var fwdMessages = newSeq[ForwardedMessage]()
    let rawFwd = obj.getOrDefault("fwd_messages")
    if rawFwd != nil:
      for msg in rawFwd.getElems():
        fwdMessages.add ForwardedMessage(userId: int msg["user_id"].num)
    
    # Создаём объект сообщения
    let message = Message(
        kind: msgPriv,  # Callback API - только приватные сообщения
        id: int obj["id"].num,  # ID сообщения
        pid: int obj["user_id"].num,  # ID отправителя
        timestamp: obj["date"].num,  # Когда было отправлено сообщение
        subject: "",  # Тема сообщения (её нет в Callback API)
        cmd: bot.processCommand(msgBody),  # Объект команды 
        body: msgBody,  # Тело сообщения
        fwdMessages: fwdMessages  # Пересланные сообщения
      )
    # Отправляем сообщение на обработку
    asyncCheck bot.checkMessage(message)

proc processRequest(req: Request) {.async, gcsafe.} =
  ## Обрабатывает запрос к серверу
  var data: JsonNode
  try:
    # Пытаемся спарсить JSON тела запроса
    data = parseJson(req.body)
  except:
    # Не получилось - игнорируем
    return
  if data["type"].str == "confirmation":
    # Отвечаем кодом для активации
    await req.respond(Http200, bot.config.confirmationCode)
  else:
    # Обрабатываем сообщение дальше
    asyncCheck processCallbackData(data)
  # Отвечаем ВК, что всё ОК
  await req.respond(Http200, "ok")

proc initCallbackApi*(self: VkBot) {.async.} = 
  # Копируем ссылку на объект бота к себе
  bot = self
  # Запускаем сервер на 5000 порту
  asyncCheck server.serve(Port(5000), processRequest)

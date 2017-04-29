include baseimports
import types
import log
import utils

const
  # Для авторизации от имени пользователя, данные официального приложения ВК
  AuthScope = "all"
  ClientId = "2274003"
  ClientSecret = "hHbZxrka2uZ6jB1inYsH"

proc encodePost(params: StringTableRef): string = 
  result = ""
  # Кодируем ключ и значение для URL
  if params != nil:
    for key, val in pairs(params):
      let 
        enck = cgi.encodeUrl(key)
        encv = cgi.encodeUrl(val)
      result.add($enck & "=" & $encv & "&")

proc postData*(client: AsyncHttpClient, url: string, params: StringTableRef):
                                    Future[AsyncResponse] {.async.} =
  ## Делает POST запрос на {url} с параметрами {params}
  var data = ""
  # Кодируем ключ и значение для URL, и добавляем к query (если есть параметры)
  if params != nil:
    for key, val in pairs(params):
      let 
        enck = cgi.encodeUrl(key)
        encv = cgi.encodeUrl(val)
      data.add($enck & "=" & $encv & "&")
  # Отправляем запрос и возвращаем его ответ
  return await client.post(url, body=data)


proc newApi*(config: BotConfig): VkApi =
  ## Создаёт новый объект VkAPi и возвращает его
  
  if config.login != "":
    # Если в конфигурации авторизация от пользователя
    let authParams = {"client_id": ClientId, 
                      "client_secret": ClientSecret, 
                      "grant_type": "password", 
                      "username": config.login, 
                      "password": config.password, 
                      "scope": "all", 
                      "v": "5.60"}.toApi
    let 
      client = newHttpClient()
      # Кодируем параметры через url encode
      body = encodePost(authParams)
      # Посылаем запрос
      data = client.postContent("https://oauth.vk.com/token", body=body)
      # Получаем наш authToken
      authToken = data.parseJson()["access_token"].str
    return VkApi(token: authToken)
  else:
    # Иначе -  
    return VkApi(token: config.token)

proc setToken*(api: VkApi, token: string) =
  ## Устанавливает токен для использования в API запросах
  api.token = token

proc callMethod*(api: VkApi, methodName: string, params: StringTableRef = nil,
        needAuth = true, flood = false): Future[JsonNode] {.async.} =
  ## Отправляет запрос к методу {methodName} с параметрами  {params} типа JsonNode
  ## и допольнительным {token}
  const
    BaseUrl = "https://api.vk.com/method/"
  let 
    http = newAsyncHttpClient()
    # Если нужна авторизация апи - используем токен апи, иначе - пустой токен
    token = if likely(needAuth): api.token else: ""
    # Создаём URL
    url = BaseUrl & "$1?access_token=$2&v=5.63&" % [methodName, token]
  
  # Если была ошибка о флуде, добавляем анти-флуд
  if flood:
    params["message"] = antiFlood() & "\n" & params["message"]
  
  # await api.apiLimiter()
  let 
    resp = await http.postData(url, params)
    # Парсим ответ от VK API в JSON
    data = parseJson(await resp.body)
    response = data.getOrDefault("response") 
  # Если есть секция response - нам нужно вернуть ответ из неё
  if likely(response != nil):
    return response
  # Иначе - проверить на ошибки, и просто вернуть ответ, если всё хорошо
  else:
    let error = data.getOrDefault("error")
    # Если есть какая-то ошибка
    if error != nil:
      case int(error["error_code"].getNum()):
      # Flood error - слишком много одинаковых сообщений
      of 9:
        # await api.apiLimiter()
        return await callMethod(api, methodName, params, needAuth, flood = true)
      else:
        logError("Ошибка при вызове $1 - $2\n$3" % [methodName, error["error_msg"].str, $data])
        # Возвращаем пустой JSON объект
        return  %*{}
    else:
      return data

proc attaches* (msg: Message, vk: VkApi): Future[seq[Attachment]] {.async.} =
  ## Получает аттачи сообщения {msg} используя объект API - {vk}
  var msg = msg
  result = @[]
  # Если у сообщения уже есть аттачи
  if msg.doneAttaches != nil:
    return msg.doneAttaches
  let 
    # ID аттача
    id = msg.id
    # Значения для запроса
    values = {"message_ids": $id, "previev_length": "1"}.toApi
    msgData = await vk.callMethod("messages.getById", values)
  if msgData == %*{}:
    return
  let message = msgData["items"][0]
  # Если нет никаких аттачей
  if not("attachments" in message):
    return
  # Проходимся по всем аттачам
  for rawAttach in message["attachments"].getElems():
    let
      # Тип аттача
      typ = rawAttach["type"].str
      # Сам аттач
      attach = rawAttach[typ]
    var 
      link = ""
      biggestRes = 0
    # Ищем ссылку на фото
    for k, v in pairs(attach):
      if "photo_" in k:
        # Парсим разрешение фотки
        let photoRes = parseInt(k[6..^1])
        # Если оно выше, чем разрешение полученных ранее фоток, используем его
        if parseInt(k.split("_")[1]) > biggestRes:
          biggestRes = photoRes
          link = v.str
    # Устанавливаем ссылку на документ
    case typ
    of "doc":
      # Ссылка на документ
      link = attach["url"].str
    of "video":
      # Ссылка с плеером видео (не работает от группы)
      try:
        link = attach["player"].str
      except KeyError:
        discard
    of "photo":
      # Проходимся по всем полям аттача
      for k, v in pairs(attach):
        if "photo_" in k:
          # Парсим разрешение фотки
          let photoRes = parseInt(k[6..^1])
          # Если оно выше, чем разрешение полученных ранее фоток, используем его
          if photoRes > biggestRes:
            biggestRes = photoRes
            link = v.str
    let
      # Получаем access_key аттача
      key = if "access_key" in attach: attach["access_key"].str else: ""
      resAttach = (typ, $attach["owner_id"].getNum(), $attach["id"].getNum(), key, link)
    # Добавляем аттач к результату
    result.add(resAttach)
  msg.doneAttaches = result

proc answer*(api: VkApi, msg: Message, body: string, attaches = "") {.async.} =
  ## Упрощённая процедура для ответа на сообщение {msg}
  let data = {"message": body, "peer_id": $msg.pid}.toApi
  # Если есть какие-то приложения, добавляем их в значения для API
  if len(attaches) > 0:
    data["attachment"] = attaches
  discard await api.callMethod("messages.send", data)

include baseimports
import types
import utils
import sequtils
import queues
const
  # Для авторизации от имени пользователя мы используем 
  # данные официального приложения ВК
  AuthScope = "all"
  ClientId = "2274003"
  ClientSecret = "hHbZxrka2uZ6jB1inYsH"

proc encodePost(params: StringTableRef): string =
  ## Кодирует параметры $params для отправки POST запросом
  result = ""
  # Кодируем ключ и значение для URL (только если есть параметры)
  if params != nil:
    for key, val in pairs(params):
      let 
        enck = cgi.encodeUrl(key)
        encv = cgi.encodeUrl(val)
      result.add($enck & "=" & $encv & "&")

proc postData*(client: AsyncHttpClient, url: string, 
              params: StringTableRef):Future[AsyncResponse] {.async.} =
  ## Делает POST запрос на {url} с параметрами {params}
  return await client.post(url, body=encodePost(params))

proc login*(login, password: string): string = 
  # Входит в VK через login и password, используя данные Android приложения
  let authParams = {"client_id": ClientId, 
                    "client_secret": ClientSecret, 
                    "grant_type": "password", 
                    "username": login, 
                    "password": password, 
                    "scope": AuthScope, 
                    "v": "5.60"}.toApi
  let 
    client = newHttpClient()
    # Кодируем параметры через url encode
    body = encodePost(authParams)
    # Посылаем запрос
    data = client.postContent("https://oauth.vk.com/token", body=body)
    # Получаем наш authToken
  result = data.parseJson()["access_token"].str

proc newApi*(config: BotConfig): VkApi =
  ## Создаёт новый объект VkAPi и возвращает его
  # Если в конфигурации авторизация от пользователя
  if config.login != "":
    return VkApi(token: login(config.login, config.password))
  # Иначе - от имени группы
  else:
    return VkApi(token: config.token)

proc `token=`*(api: VkApi, token: string) =
  ## Устанавливает токен для использования в API запросах
  api.token = token


proc toExecute(methodName: string, params: StringTableRef): string {.inline.} = 
  # Если нет параметров, нам не нужно их обрабатывать
  if params.len == 0:
    return "API." & methodName & "()"
  let
    # Получаем последовательность из параметров вызовы
    pairsSeq = toSeq(params.pairs)
    # Составляем последовательность аргументов к вызову API
    keyValSeq = pairsSeq.mapIt("\"$1\":\"$2\"" % [it.key, it.value.replace("\n", "<br>")])
  # Возвращаем полный вызов к API с именем метода и параметрами
  return "API." & methodName & "({" & keyValSeq.join(", ") & "})"

type
  # Кортеж для обозначения нашего запроса к API через метод VK API - execute
  MethodCall = tuple[myFut: Future[JsonNode], 
                     name: string,
                     params: StringTableRef]

# Создаём очередь запросов (по умолчанию делаем её из 32 элементов)
var requests = initQueue[MethodCall](32)

proc callMethod*(api: VkApi, methodName: string, params: StringTableRef = nil,
                 needAuth = true, flood = false, 
                 useExecute = true): Future[JsonNode] {.async.} =
  ## Отправляет запрос к методу {methodName} с параметрами  {params} типа JsonNode
  ## и допольнительным {token} (по умолчанию - через execute)
  const
    BaseUrl = "https://api.vk.com/method/"
  
  let
    http = newAsyncHttpClient()
    # Если нужна авторизация апи - используем токен апи, иначе - пустой токен
    token = if likely(needAuth): api.token else: ""
    # Создаём URL
    url = BaseUrl & "$1?access_token=$2&v=5.63&" % [methodName, token]
  # Переменная, в которую записывается ответ от API в JSON
  var jsonData: JsonNode
  # Если нужно использовать execute
  if likely(useExecute):
    # Создаём future для получения информации
    let apiFuture = newFuture[JsonNode]("callMethod")
    # Добавляем его в очередь запросов
    requests.add((apiFuture, methodName, params))
    # Ожидаем получения результата от execute()
    jsonData = await apiFuture
  # Иначе - обычный вызов API
  else:
    
    let 
      # Отправляем запрос к API
      req = await http.postData(url, params)
      # Получаем ответ
      resp = await req.body
    # Если была ошибка о флуде, добавляем анти-флуд
    if flood:
      params["message"] = antiFlood() & "\n" & params["message"]
    jsonData = parseJson(resp)
  
  let response = jsonData.getOrDefault("response") 
  # Если есть секция response - нам нужно вернуть ответ из неё
  if likely(response != nil):
    return response
  # Иначе - проверить на ошибки, и просто вернуть ответ, если всё хорошо
  else:
    let error = jsonData.getOrDefault("error")
    # Если есть какая-то ошибка
    if error != nil:
      case error["error_code"].getNum():
      # Flood error - слишком много одинаковых сообщений
      of 9:
        # await api.apiLimiter()
        return await callMethod(api, methodName, params, needAuth, flood = true)
      of 14:
        # TODO: Обработка капчи
        let 
          sid = error["captcha_sid"].str
          img = error["captcha_img"].str
        error("Капча $1 - $2" % [sid, img])
        params["captcha_sid"] = sid
        #params["captcha_key"] = key
        #return await callMethod(api, methodName, params, needAuth)
      else:
        error("Ошибка при вызове $1 - $2\n$3" % [methodName, error["error_msg"].str, $jsonData])
        
    else:
      return jsonData
  # Возвращаем пустой JSON объект
  return  %*{}

proc executeCaller*(api: VkApi) {.async.} = 
  ## Бесконечный цикл, проверяет последовательность requests
  while true:
    # Спим 350 мс
    await sleepAsync(350)
    # Если в очереди нет элементов
    if requests.len == 0:
      continue
    # Последовательность вызовов API в виде VKScript
    var items: seq[string] = @[]
    # Последовательность future
    var futures: seq[Future[JsonNode]] = @[]
    # Максимальное кол-во запросов к API через execute минус 1
    var count = 24
    # Пока мы не опустошим нашу очередь или лимит запросов кончится
    while requests.len != 0 and count != 0:
      # Получаем самый старый элемент
      let (fut, name, params) = requests.pop()
      # Добавляем в items его вызов в виде строки VKScript
      items.add name.toExecute(params)
      futures.add(fut)
      # Декрементируем count
      dec count
    # Составляем код VK Script
    let code = "return [" & items.join(", ") & "];"
    # Отправляем запрос execute
    let answer = await api.callMethod("execute", {"code": code}.toApi, 
                                      useExecute = false)
    # Проходимся по результатам и futures
    for data in zip(answer.getElems(), futures):
      let (item, fut) = data
      # Завершаем future с результатом
      fut.complete(item)


proc attaches*(msg: Message, vk: VkApi): Future[seq[Attachment]] {.async.} =
  ## Получает аттачи сообщения {msg} используя объект API - {vk}
  result = @[]
  # Если у сообщения уже есть аттачи
  if msg.doneAttaches != nil:
    return msg.doneAttaches
  let 
    # Значения для запроса
    values = {"message_ids": $msg.id, "previev_length": "1"}.toApi
    msgData = await vk.callMethod("messages.getById", values)
  # Если произошла ошибка при получении данных - ничего не возвращаем
  if msgData == %*{}:
    return
  
  let 
    message = msgData["items"][0]
    attaches = message.getOrDefault("attachments")
  # Если нет ни одного аттача
  if attaches == nil:
    return
  # Проходимся по всем аттачам
  for rawAttach in attaches.getElems():
    let
      # Тип аттача
      typ = rawAttach["type"].str
      # Сам аттач
      attach = rawAttach[typ]
    var
      # Ссылка на аттач (ссылка на фотографию, документ, превью видео)
      link = ""
    # Ищем ссылку на аттач
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
      # Максимальное разрешение фотографии, которое мы нашли
      var biggestRes = 0
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
      # Если есть access_key - добавляем его, иначе - ничего не добавляем
      key = if "access_key" in attach: attach["access_key"].str else: ""
      resAttach = (typ, $attach["owner_id"].getNum(), 
                  $attach["id"].getNum(), key, link)
    # Добавляем аттач к результату
    result.add(resAttach)
  msg.doneAttaches = result

proc answer*(api: VkApi, msg: Message, body: string, attaches = "") {.async.} =
  ## Упрощённая процедура для ответа на сообщение {msg}
  let data = {"message": body, "peer_id": $msg.pid}.toApi
  # Если есть какие-то аттачи, добавляем их в значения для API
  if attaches.len > 0: data["attachment"] = attaches
  discard await api.callMethod("messages.send", data)

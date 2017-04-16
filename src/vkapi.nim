include baseimports
import types
import log
import utils

const 
  MaxRPS: byte = 3
  SleepTime = 350

proc postData*(client: AsyncHttpClient, url: string, params: StringTableRef):
                                    Future[AsyncResponse] {.async.} =
  ## Делает POST запрос на {url} с параметрами {params}
  var data = ""
  # Кодируем ключ и значение для URL, и добавляем к query
  for key, val in pairs(params):
    let 
      enck = cgi.encodeUrl(key)
      encv = cgi.encodeUrl(val)
    data.add($enck & "=" & $encv & "&")
  # Отправляем запрос и возвращаем его ответ
  return await client.post(url, body=data)


proc newApi*(token = ""): VkApi =
  ## Создаёт новый объект VkAPi и возвращает его
  return VkApi(token: token)

proc setToken*(api: VkApi, token: string) =
  ## Устанавливает токен для использования в API запросах
  api.token = token


proc apiLimiter(api: VkApi) {.async.} =
  ## Увеличиваеи кол-во запущенных запросов, ждёт SleepTime мс, и уменьшает
  ## кол-во запущенных запросов
  ## Сделано для ограничения 3 запросов в секунду(350*3 = 1150 - на всякий случай)
  inc(api.reqCount)
  await sleepAsync(SleepTime)
  dec(api.reqCount)
  
proc callMethod*(api: VkApi, methodName: string, params = newStringTable(),
        needAuth = true, flood = false): Future[JsonNode] {.async.} =
  ## Отправляет запрос к методу {methodName} с параметрами  {params} типа JsonNode
  ## и допольнительным {token}
  let http = newAsyncHttpClient()
  let 
    # Если нужна авторизация апи - используем токен апи, иначе - пустой токен
    token = if likely(needAuth): api.token else: ""
    # Создаём URL
    url = "https://api.vk.com/method/" & interp("$methodName?access_token=$token&v=5.63&")
  
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
    if likely(error != nil):
      case int(error["error_code"].getNum()):
        # Flood error - слишком много одинаковых сообщений
        of 9:
          # await api.apiLimiter()
          return await callMethod(api, methodName, params, needAuth, flood = true)
        else:
          logError("Ошибка при вызове " & methodName & "\n" & $data)
          # Возвращаем пустой JSON объект
          return  %*{}
    else:
      return data

proc answer*(api: VkApi, msg: Message, body: string, attaches = "") {.async.} =
  ## Упрощённая процедура для ответа на сообщение {msg}
  let data = {"message": body, "peer_id": $msg.pid}.api
  # Если есть какие-то приложения, добавляем их в значения для API
  if len(attaches) > 0:
    data["attachment"] = attaches
  discard await api.callMethod("messages.send", data)

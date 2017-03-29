import future
import httpclient  # Для HTTP запросов
import strtabs  # Для быстрых словарей
import json  # Для парсинга JSON
import strfmt  # Для использования interp
import cgi  # Для url кодирования
import uri  # Для парсинга URL
import types  # Общие типы бота
import random  # для анти флуда
import strutils
import asyncdispatch
import utils

const 
  MaxRPS: byte = 3
  SleepTime = 350

proc getQuery*(client: AsyncHttpClient, url: string, params: StringTableRef):
                                    Future[AsyncResponse] {.async.} =
  ## Делает GET запрос на {url} с query параметрами {params}
  var newUrl = parseUri(url)
  # Если query пустой - добавляем начало - ?
  if likely(newUrl.query == ""):
    newUrl.query = "?"
  # Кодируем ключ и значение для URL, и добавляем к query
  for key, val in pairs(params):
    let enck = cgi.encodeUrl(key)
    let encv = cgi.encodeUrl(val)
    newUrl.query.add($enck & "=" & $encv & "&")
  # Отправляем запрос и возвращаем его ответ
  return await client.get($newUrl)


proc newApi*(token: string = ""): VkApi =
  ## Создаёт новый объект VkAPi и возвращает его
  return VkApi(token: token, http: newAsyncHttpClient())

proc setToken*(api: VkApi, token: string) =
  ## Устанавливает токен для использования в API запросах
  api.token = token

proc antiFlood(): string =
   ## Служит ля обхода анти-флуда Вконтакте (генерирует пять случайных букв)
   const Alphabet = "ABCDEFGHIJKLMNOPQRSTUWXYZ"
   return lc[random(Alphabet) | (x <- 0..5), char].join("")


proc apiLimiter(api: VkApi) {.async.} =
  ## Увеличиваеи кол-во запущенных запросов, ждёт SleepTime мс, и уменьшает
  ## кол-во запущенных запросов
  ## Сделано для ограничения 3 запросов в секунду(350*3 = 1150 - на всякий случай)
  inc(api.reqCount)
  await sleepAsync(SleepTime)
  dec(api.reqCount)
  
proc callMethod*(api: VkApi, methodName: string, params: StringTableRef = newStringTable(),
        needAuth: bool = true, flood: bool = false): Future[JsonNode] {.async.} =
  ## Отправляет запрос к методу {methodName} с параметрами  {params} типа JsonNode
  ## и допольнительным {token}
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
    resp = await api.http.getQuery(url, params)
    # Парсим ответ от VK API в JSON
    data = parseJson(await resp.body)
  #  Если есть секция response - нам нужно вернуть ответ из неё
  if likely("response" in data):
    return data["response"]
  # Иначе - проверить на ошибки, и просто вернуть ответ, если всё хорошо
  else:
    if likely("error" in data):
      case int(data["error"]["error_code"].getNum()):
        # Flood error - слишком много одинаковых сообщений
        of 9:
          # await api.apiLimiter()
          return await callMethod(api, methodName, params, needAuth, flood = true)
        else:
          echo("Ошибка при вызове " & methodName & "\n" & $data)
          # Возвращаем пустой JSON объект
          return  %*{}
    else:
      return data

proc answer*(api: VkApi, msg: Message, body: string, 
                        attaches: string = "") {.async.} =
  ## Упрощённая процедура для ответа на сообщение {msg}
  let data = {"message": body, "peer_id": $msg.peerId}.api
  # Если есть какие-то приложения, добавляем их в значения для API
  if len(attaches) > 0:
    data["attachment"] = attaches
  discard await api.callMethod("messages.send", data)

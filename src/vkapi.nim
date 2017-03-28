import future
import httpclient  # Для HTTP запросов
import tables  # Для таблиц
import json  # Для парсинга JSON
import strfmt  # Для использования interp
import cgi  # Для url кодирования
import uri  # Для парсинга URL
import types  # Общие типы бота
import random  # для анти флуда
import strutils
import asyncdispatch


const 
  MaxRPS: byte = 3
  SleepTime = 350

proc getQuery*(client: AsyncHttpClient, url: string, params: KeyVal | Table):
                                    Future[AsyncResponse] {.async.} =
  ## Делает GET запрос на {url} с query параметрами {params}
  var newUrl = parseUri(url)
  # Если query пустой - добавляем начало - ?
  if newUrl.query == "":
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
  
proc callMethod*(api: VkApi, methodName: string, params: KeyVal = @[],
        token: string = "", flood: bool = false): Future[JsonNode] {.async.} =
  ## Отправляет запрос к методу {methodName} с параметрами  {params} типа JsonNode
  ## и допольнительным {token}
  # Если нам дали кастомный токен в процедуру, юзаем его, иначе - тот,
  # с которым инициализировались
  let token = if len(token) > 0: token else: api.token
  # Создаём URL
  let url = "https://api.vk.com/method/" & interp("$methodName?access_token=$token&v=5.63&")
  var newParams = params.toTable()
  if flood:
    newParams["message"] = antiFlood() & "\n" & newParams["message"]
  # Парсим ответ от VK API в JSON
  await api.apiLimiter()
  let resp = await api.http.getQuery(url, newParams)

  let body = await resp.body
  let data = parseJson(body)
  #  Если есть секция response - нам нужно вернуть её элементы
  if "response" in data:
    return data["response"]
  # Иначе - проверить на ошибки, и просто вернуть ответ, если всё хорошо
  else:
    if likely("error" in data):
      case int(data["error"]["error_code"].getNum()):
        # флуд контроль
        of 9:
          await api.apiLimiter()
          return await callMethod(api, methodName, params, token, flood = true)
        else:
          echo("Ошибка при вызове " & methodName)
          echo $data
          # Возвращаем пустой JSON объект
          return  %*{}
    else:
      return data

proc answer*(api: VkApi, msg: Message, body: string) {.async.} =
  ## Упрощённый метод для ответа на сообщение {msg}
  let data = @[("message", body), ("peer_id", $msg.peerId)]
  discard await api.callMethod("messages.send", data)

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


proc getQuery*(client: HttpClient, url: string, params: KeyVal | Table): Response =
  ## Делает GET запрос на {url} с query параметрами {params}
  var newUrl = parseUri(url)
  # Если query пустой - добавляем начало - ?
  if newUrl.query == "":
    newUrl.query = "?"
  # Энкодим ключ и значение, и добавляем к query
  for key, val in pairs(params):
    let enck = cgi.encodeUrl(key)
    let encv = cgi.encodeUrl(val)
    newUrl.query.add($enck & "=" & $encv & "&") 
  # Отправляем запрос и возвращаем ответ
  return client.get($newUrl)


proc initApi*(token: string = ""): VkApi =
  ## Создаёт новый объект VkAPi и возвращает его
  return VkApi(token: token, http: newHttpClient())

proc setToken*(api:var VkApi, token: string) =
  ## Устанавливает токен для использования в API запросах
  api.token = token

proc antiFlood(): string =
   const Alphabet = "ABCDEFGHIJKLMNOPQRSTUWXYZ"
   return lc[random(Alphabet) | (x <- 0..5), char].join("")


proc callMethod*(api: VkApi, methodName: string, params: KeyVal = [], 
                    token: string = "", flood: bool = false): JsonNode =
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
  let data = parseJson(api.http.getQuery(url, newParams).body)
  #  Если есть секция response - нам нужно вернуть элементы из неё
  if "response" in data:
    return data["response"]
  # Иначе - проверить на ошибки, и вернуть сам JSON если всё хорошо
  else:
    if "error" in data:
      case int(data["error"]["error_code"].getNum()):
        # флуд контроль
        of 9:
          return callMethod(api, methodName, params, token, flood = true)
        else:
          echo("Ошибка при вызове " & methodName)
          echo $data
          # Возвращаем пустой JSON объект
          return  %*{}
    else:
      return data

proc answer*(api: VkApi, msg: Message, body: string) =
    ## Упрощённый метод для ответа на сообщение
    let data = {"message": body, "peer_id": $msg.peerId}
    discard api.callMethod("messages.send", data)
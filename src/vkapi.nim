import httpclient  # Для HTTP запросов
import tables  # Для таблиц
import json  # Для парсинга JSON
import strfmt  # Для использования interp
import cgi  # Для url кодирования
import uri  # Для парсинга URL
import types  # Общие типы бота

proc getQuery*(client: HttpClient, url: string, params: KeyVal): Response =
  ## Get {url} with query parameters {params} as KeyVal
  var newUrl = parseUri(url)
  if newUrl.query == "":
    newUrl.query = "?"
  for pair in params:
    let enck = cgi.encodeUrl(pair.key)
    let encv = cgi.encodeUrl(pair.val)
    newUrl.query.add($enck & "=" & $encv & "&") 
  return client.get($newUrl)


proc newAPI*(token: string = ""): VkApi =
  ## Creates new API object and returns it
  return VkApi(token: token, http: newHttpClient())

proc setToken*(api:var VkApi, token: string) =
  ## Set token for use in API requests 
  api.token = token

proc callMethod*(api: VkApi, methodName: string, params: KeyVal = [], token: string = ""): JsonNode =
  ## Access {methodName} endpoint of VK API with JsonNode {params} and optional {token}
  let token = if len(token) > 0: token else: api.token
  let url = "https://api.vk.com/method/" & interp("$methodName?access_token=$token&v=5.63&")
          
  let data = parseJson(api.http.getQuery(url, params).body)
  # If there's response section - we need return items from inside of it
  if "response" in data:
    return data["response"]
  # Else - check for error and return data if everything's OK
  else:
    if "error" in data:
      echo("Error calling " & methodName)
      echo $data
      # Return empty JSON Node
      return  %*{}
    return data

proc answer*(api: VkApi, msg: Message, body: string) =
    ## As messages.send is the most used method in the bot, we can make
    ## this simple and short procedure to make our lifes easier :)
    let data = {"message": body, "peer_id": $msg.peerId}
    discard api.callMethod("messages.send", data)
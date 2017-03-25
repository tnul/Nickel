import httpclient  # for http requests
import tables  # for dict-like tables 
import json  # for parsing json response
import strfmt  # for interp 
import cgi  # for url encoding 

import types

const 
  noParams* = {"a": "b"}.toTable

let emptyJson* = %* {}

proc newAPI* (token: string): VkApi =
  ## Creates new API object and returns it
  return VKAPI(token: token, http: newHttpClient())

proc setToken* (api:var VkApi, token: string) =
    ## Set token to use for API requests 
    api.token = token

proc callMethod* (api: VkApi, methodName: string, params: Table = newTable[string, int](), token: string = ""): JsonNode =
  ## Access {methodName} endpoint of VK API with table {params} and optional {token}
  let token = if len(token) > 0: token else: api.token
  let url = "https://api.vk.com/method/" & interp("$methodName?access_token=$token&v=5.63&")
  # Query string will be something like a=b&c=d&e=f&
  var query = ""
  if params != noParams:
    for k, v in pairs(params):
      let enck = cgi.encodeUrl(k)
      let encv = cgi.encodeUrl(v)
      query.add(interp"$enck=$encv" & "&") 
        
  let data = parseJson(api.http.get(url & query).body)
  # If there's response section - we need return items from inside of it
  if "response" in data:
    return data["response"]
  # Else - check for error and return data if everything's OK
  else:
    if "error" in data:
      echo("Error calling " & methodName)
      echo $data
      # Return empty JSON Node
      return  %* {}
    return data

proc answer* (api: VkApi, msg: Message, body: string) =
    ## As messages.send is the most used method in the bot, we can make
    ## this simple and short procedure to make our lifes easier :)
    var data = {"message": body, "peer_id": $msg.peerId}.toTable()
    discard api.callMethod("messages.send", data)
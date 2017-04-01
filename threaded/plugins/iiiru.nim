include base
import base64, httpclient, unicode

const
  Key = "some very-very long string without any non-latin characters due to different string representations inside of variable programming languages"
  KeyLen = len(Key)
  BotId = "6d339d3a-c79e-4314-8fd4-2fdaed0cb635"
  InitUrl = "http://iii.ru/api/2.0/json/Chat.init/"
  ChatUrl = "http://iii.ru/api/2.0/json/Chat.request"

let client = newAsyncHttpClient()

proc interXor(message: string): string = 
  result = ""
  for ind, letter in message:
    result &= chr(ord(letter) xor ord(Key[ind mod KeyLen]))

proc encrypt(message: string): string = 
  return base64.encode(interXor(message))

proc decrypt(message: string): string = 
  let test = interXor(base64.decode(message))

proc initIII(id: string): Future[JsonNode] {.async.} =
  let resp = await client.getContent(InitUrl & BotId & "/" & id)
  let res = resp.decrypt()
  echo $res
  return parseJson(res)

proc chatIII(id, msg: string): Future[JsonNode] {.async.} =
  var decoded = escapeJson(msg)
  echo $decoded
  let toSend = base64.encode("[\"" & id & "\",\"" & msg & "\"]").encrypt()
  let resp = await client.request(ChatUrl, httpMethod = HttpPost, body = toSend)
  let body = await resp.body
  return parseJson base64.decode body.decrypt


proc main() {.async.} = 
  let resp = await initIII("333111")
  echo $resp
  let data = await chatIII("333111", "привет")
  echo $data

asyncCheck main()
asyncdispatch.runForever()
  

include base
import base64, httpclient
const
  Key = "some very-very long string without any non-latin characters due to different string representations inside of variable programming languages"
  KeyLen = len(Key)
  # ID вашего инфа. По умолчанию стоит ID первого инфа в глобальном рейтинге
  BotID = "970c8b3d-2e25-471d-8aab-efc87bcb7155"

proc interXor(msg: string): string = 
  result = ""
  for ind, letter in msg:
    result &= chr(ord(letter) xor ord(Key[ind mod KeyLen]))
  return result

proc encrypt(msg: string): string = 
  result = base64.encode interXor(msg)

proc decrypt(msg: string): string = 
  result = base64.decode interXor base64.decode(msg)

proc init(id: string): Future[string] {.async.}= 
  let 
    client = newAsyncHttpClient()
    data = await client.getContent("http://iii.ru/api/2.0/json/Chat.init/$1/$2" % [BotID, id])
    jsonData = parseJson decrypt(data)
  result = jsonData["result"]["cuid"].str

proc chat(ses: string, msg: string): Future[string] {.async.} = 
  let 
    client = newAsyncHttpClient()
    toSend = "[\"$1\",\"$2\"]" % [ses, msg]
    hashed = encrypt(base64.encode(toSend))
    req = await client.post("http://iii.ru/api/2.0/json/Chat.request", body=hashed)
  return parseJson(decrypt(await req.body))["result"]["text"]["value"].str

var 
  sessions = initTable[string, string]()

module "Бот iii.ru":
  command "сеть", "бот", "iii":
    usage = "сеть <текст> - отправить боту сообщение"
    let 
      text = msg.cmd.args.join(" ")
      uid = $msg.pid
    if not sessions.hasKey(uid):
      sessions[uid] = await init(uid)
    let sess = sessions[uid]
    await api.answer(msg, await sess.chat(text))
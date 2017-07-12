include base
import base64, httpclient

const
  Key = "some very-very long string without any non-latin characters due to different string representations inside of variable programming languages"
  KeyLen = len(Key)
  # ID инфа. По умолчанию стоит ID первого инфа в глобальном рейтинге
  BotID = "970c8b3d-2e25-471d-8aab-efc87bcb7155"

proc interXor(msg: string): string = 
  ## Реализация XOR с ключом
  result = ""
  for ind, letter in msg:
    result &= chr(ord(letter) xor ord(Key[ind mod KeyLen]))
  return result

proc encrypt(msg: string): string = 
  ## Шифрует строку $msg для отправки к iii
  result = base64.encode interXor(msg)

proc decrypt(msg: string): string = 
  ## Расшифровывает строку $msg, полученную от iii
  result = base64.decode interXor base64.decode(msg)

proc init(id: string): Future[string] {.async.} = 
  const
    InitUrl = "http://iii.ru/api/2.0/json/Chat.init/$1/$2"
  let 
    client = newAsyncHttpClient()
    # Отправляем запрос на инициализацию сессии чата
    data = await client.getContent(InitUrl % [BotID, id])
    # Расшифровываем ответ
    jsonData = parseJson decrypt(data)
  # Возвращаем ID сессии
  result = jsonData["result"]["cuid"].str

proc chat(sess, msg: string): Future[string] {.async.} = 
  let 
    client = newAsyncHttpClient()
    # Формируем данные для отправки - ["код сессии","сообщение"]
    toSend = "[\"$1\",\"$2\"]" % [sess, msg]
    # Шифруем данные
    hashed = encrypt(base64.encode(toSend))
    # Отправляем запрос к iii
    req = await client.post("http://iii.ru/api/2.0/json/Chat.request", body=hashed)
  # Возвращаем строку - ответ инфа
  return parseJson(decrypt(await req.body))["result"]["text"]["value"].str

var 
  sessions = initTable[string, string]()

module "&#128172;", "Бот iii.ru":
  command "сеть", "iii", "инф", "сеть,", "инф,":
    usage = "сеть <текст> - отправить боту сообщение"
    let
      uid = $msg.pid
    if not sessions.hasKey(uid):
      sessions[uid] = await init(uid)
    let sess = sessions[uid]
    answer(await sess.chat(text))

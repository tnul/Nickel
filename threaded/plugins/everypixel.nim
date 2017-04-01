include base
import httpclient, math

const Url = "https://services2.microstock.pro/aesthetics/quality"



proc getQuality(url: string): float = 
  let 
    client = newHttpClient()
    photoData = client.getContent(url)
  var data = newMultipartData()
  data["data"] = ("test", "image/jpg", photoData)
  let resp = client.post(Url, multipart=data)
  let answer = resp.body
  return round(parseJson(answer)["quality"]["score"].getFNum()*100, 1)

proc call*(api: VkApi, msg: Message)= 
# Нам нужна информация о сообщении для получения URL фотографии.
  for attach in msg.attaches:
    if attach.kind != "photo":
      return
  let 
    msgData = api.callMethod("messages.get", {"message_ids": $msg.id}.api)
    data = msgData["items"][0]
  if not("attachments" in data):
    api.answer(msg, "Какие фотки мне оценивать-то?")
    return
  
  var answer: string = ""
  # Этот плагин может и получать данные для нескольких фотографий, но это медленно,
  # и бот блокируется
  for ind, attach in data["attachments"].getElems():
    # Если это не фотография
    if attach["type"].str != "photo":
      continue
    # Получаем URL фотографии с макс. разрешением
    let photo = attach["photo"]
    var photoUrl: string
    # Костыли из-за ВК - нельзя просто так узнать макс. размер фотки
    try:
      photoUrl = photo["photo_2560"].str
    except:
      try:
        photoUrl = photo["photo_1280"].str
      except:
        try:
          photoUrl = photo["photo_604"].str
        except:
          photoUrl = photo["photo_75"].str
    # yield quality

    # if quality.failed:
    #   await api.answer(msg, "Что-то пошло не так :(")
    #   return
    # let qualityData = quality.read()
    let res = getQuality(photoUrl)
    #api.answer(msg, "Крутость фотки - " & $(res) & " процентов")
    #return
    answer.add($(ind + 1) & "-я фотка - " & $res & " процентов крутости\n")
  api.answer(msg, answer)
    

  
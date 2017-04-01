include base
import httpclient, math

const Url = "https://services2.microstock.pro/aesthetics/quality"



proc getQuality(url: string): Future[float] {.async.} = 
  benchmark "Downloading photo from VK":
    let 
      client = newAsyncHttpClient()
      photoData = await client.getContent(url)
  var data = newMultipartData()
  data["data"] = ("test", "image/jpg", photoData)
  benchmark "Posting data to Everypixel":
    let resp = await client.post(Url, multipart=data)
    let answer = await resp.body
  return round(parseJson(answer)["quality"]["score"].getFNum()*100, 1)

proc call*(api: VkApi, msg: Message) {.async.} = 
# Нам нужна информация о сообщении для получения URL фотографии.
  for attach in msg.attaches:
    if attach.kind != "photo":
      return
  benchmark "Getting message info":
    let 
      msgData = await api.callMethod("messages.get", {"message_ids": $msg.id}.api)
      data = msgData["items"][0]
  if not("attachments" in data):
    await api.answer(msg, "Какие фотки мне оценивать-то?")
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
    benchmark "Getting quality":
      let res = await getQuality(photoUrl)
    benchmark "Answering":
      await api.answer(msg, "Крутость фотки - " & $(res) & " процентов")
    return
    #answer.add($(ind + 1) & "-я фотка - " & $qualityData & " процентов крутости")
  # await api.answer(msg, answer)
    

  
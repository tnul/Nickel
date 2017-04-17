include base
import httpclient, math

const Url = "https://services2.microstock.pro/aesthetics/quality"



proc getQuality(url: string): Future[float] {.async.} = 
  let 
    client = newAsyncHttpClient()
    photoData = await client.getContent(url)
  # Создаём Multipart Data
  var data = newMultipartData()
  data["data"] = ("test", "image/jpg", photoData)
  # Отправляем файл на сервер EveryPixel
  let 
    resp = await client.post(Url, multipart=data)
    answer = await resp.body
  return round(parseJson(answer)["quality"]["score"].getFNum()*100)

proc everypixel(api: VkApi, msg: Message) {.async.} = 
# Нам нужна информация о сообщении для получения URL фотографии.
  let attaches = await msg.attaches(api)

  if len(attaches) < 1:
    await api.answer(msg, "Какие фотки мне оценивать-то?")
    return
  
  var answer: string = ""
  for ind, attach in attaches:
    # Если это не фотография
    if attach.kind != "photo":
      continue
    
    let res = await getQuality(attach.link)
    #await api.answer(msg, "Крутость фотки - " & $(res) & " процентов")
    #return
    answer.add($(ind + 1) & "-я фотка - " & $res & "% крутости\n")
  if answer == "":
    await api.answer(msg, "Какие фотки мне оценивать-то?")
  else:
    await api.answer(msg, answer)

everypixel.handle("оцени", "качество")
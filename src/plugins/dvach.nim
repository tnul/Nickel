include base

const 
  Answers = ["Каеф", "Не баян (баян)", "Ну держи!"]
  DvachGroupId = "-22751485"
  MemesGroupId = "-129950840"

proc giveMemes(api: VkApi, msg: Message, groupId: string) {.async.} = 
    ## Получает случайную фотографию из постов группы
    var photo: JsonNode = nil


    var values = {"owner_id": groupId, 
                  "offset": $(random(1984) + 1), 
                  "count": "1"}.api 
      
    # Пока мы не нашли фотографию
    while photo == nil:
        # Отправляем API запрос
        let data = await api.callMethod("wall.get", values, needAuth = false)
        let attaches = data["items"][0].getOrDefault("attachments")
        # Если к посту прикреплены записи
        if attaches != nil:
            photo = attaches[0].getOrDefault("photo")
        # Берём другой случайный оффсет
        values["offset"] = $(random(1984)+1)
    # ID владельца фото
    let oid = $photo["owner_id"].getNum()
    # ID самого приложения
    let attachId = $photo["id"].getNum()
    # Access key может понадобиться, если группа закрытая 
    let accessKey = photo["access_key"].str

    let attachment = interp"photo${oid}_${attachId}_${accessKey}"
    await api.answer(msg, random(Answers), attaches = attachment)


proc call*(api: VkApi, msg: Message, dvach: bool = false) {.async.} = 
  if msg.cmd.command == "двач":
    await giveMemes(api, msg, DvachGroupId)
  else:
    await giveMemes(api, msg, MemesGroupId)

include base

const 
  Answers = ["Каеф", "Не баян (баян)", "Ну держи!"]
  DvachGroupId = "-22751485"
  MemesGroupId = "-129950840"

proc giveMemes(api: VkApi, msg: Message, groupId: string) = 
    ## Получает случайную фотографию из постов группы
    var photo: JsonNode = nil


    var values = {"owner_id": groupId, 
                  "offset": $(random(1984) + 1), 
                  "count": "1"}.api 
      
    # Пока мы не нашли фотографию
    while photo == nil:
        # Отправляем API запрос
        let data = api.callMethod("wall.get", values, needAuth = false)
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
    api.answer(msg, random(Answers), attaches = attachment)


proc call*(api: VkApi, msg: Message, dvach: bool = false) = 
  if dvach:
    giveMemes(api, msg, DvachGroupId)
  else:
    giveMemes(api, msg, MemesGroupId)

include base

const 
  Answers = ["Каеф", "Не баян (баян)", "Ну держи!"]
  DvachGroupId = "-22751485"  # https://vk.com/ru2ch
  MemesGroupId = "-86441049"  # https://vk.com/hard_ps

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


proc dvach(api: VkApi, msg: Message) {.async.} = 
  await giveMemes(api, msg, DvachGroupId)

proc memes(api: VkApi, msg: Message) {.async.} =
  await giveMemes(api, msg, MemesGroupId)

dvach.handle("двач", "2ch")
memes.handle("мемы", "мемчики", "мемасы", "мемасики")

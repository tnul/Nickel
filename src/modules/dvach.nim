include base

const
  Answers = [
    "Каеф", "Не баян (баян)", 
    "Ну держи!", "А вот и баянчики подъехали"
  ]
  DvachGroupId = "-22751485"  # https://vk.com/ru2ch
  MemesGroupId = "-86441049"  # https://vk.com/hard_ps

proc giveMemes(api: VkApi, msg: Message, groupId: string) {.async.} = 
  ## Получает случайную фотографию из постов группы с id groupId
  var pic: JsonNode
  # Пока мы не нашли картинку
  while pic.isNil():
    let 
      # Отправляем API запрос
      data = await api@wall.get(owner_id=groupId, 
                                offset=random(1984+1), count=1)
      attaches = data["items"][0].getOrDefault("attachments")
    # Если у поста есть аттачи
    if attaches != nil:
        pic = attaches[0].getOrDefault("photo")
  let 
    # ID владельца картинки
    oid = $pic["owner_id"].getNum()
    # ID самой картинки
    attachId = $pic["id"].getNum()
    # Access key может понадобиться, если группа закрытая 
    accessKey = pic["access_key"].str
    attachment = "photo$1_$2_$3" % [oid, attachId, accessKey]
  answer(random(Answers), attachment)

module "﷽", "Двач - случайные мемы с двача или из https://vk.com/hard_ps":
  command "двач", "2ch":
    usage = "двач - случайный мем с двача"
    await giveMemes(api, msg, DvachGroupId)

  command "мемы", "мемчики", "мемасы", "мемасики", "мемас":
    usage = "мемы - случайный мем из https://vk.com/hard_ps"
    await giveMemes(api, msg, MemesGroupId)
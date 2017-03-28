include base


const AdminUid = 170831732

proc call*(api: VkApi, msg: Message) {.async.} =
  if msg.peerId == AdminUid:
    await api.answer(msg, "Выключаюсь...")
    echo("Бот выключается по запросу администратора vk.com/id " & $msg.peerId)
    quit(0)
  else:
    await api.answer(msg, "Извини, но ты не администратор :)")
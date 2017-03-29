include base

const AdminUid = 170831732

proc call*(api: VkApi, msg: Message) {.async.} =
  if unlikely(msg.peerId == AdminUid):
    await api.answer(msg, "Выключаюсь...")
    echo("Бот выключается по запросу администратора https://vk.com/id" & $msg.peerId)
    quit(0)
  else:
    await api.answer(msg, "Извини, но ты не администратор :)")
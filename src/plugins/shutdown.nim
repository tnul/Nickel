include base

const AdminUid = 170831732

proc turnoff(api: VkApi, msg: Message) {.async.} =
  if unlikely(msg.pid == AdminUid):
    await api.answer(msg, "Выключаюсь...")
    echo("Бот выключается по запросу администратора https://vk.com/id" & $msg.pid)
    quit(0)
  else:
    await api.answer(msg, "Извини, но ты не администратор :)")

turnoff.handle("выключись", "выключение")
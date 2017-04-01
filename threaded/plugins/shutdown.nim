include base

const AdminUid = 170831732

proc call*(api: VkApi, msg: Message) =
  if unlikely(msg.pid == AdminUid):
    api.answer(msg, "Выключаюсь...")
    echo("Бот выключается по запросу администратора https://vk.com/id" & $msg.pid)
    quit(0)
  else:
    api.answer(msg, "Извини, но ты не администратор :)")
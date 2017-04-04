include base
import times

proc time(api: VkApi, msg: Message) {.async.} =
  await api.answer(msg, "Текущие дата и время по МСК:\n" & utils.getMoscowTime())

time.handle("время", "дата")
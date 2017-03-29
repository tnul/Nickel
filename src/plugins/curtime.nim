include base
import times

proc call*(api: VKAPI, msg: Message) {.async.} =
  await api.answer(msg, "Текущие дата и время:\n" & utils.getMoscowTime())
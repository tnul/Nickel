include base
import times

proc call*(api: VKAPI, msg: Message) {.async.} =
  await api.answer(msg, "Текущее время - " & utils.getMoscowTime())
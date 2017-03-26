include base
import times

proc call*(api: VKAPI, msg: Message) =
  api.answer(msg, "Текущее время - " & getClockStr())
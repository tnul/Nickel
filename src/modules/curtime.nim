include base
import times

command "время", "дата":
  await api.answer(msg, "Текущие дата и время по МСК:\n" & utils.getMoscowTime())
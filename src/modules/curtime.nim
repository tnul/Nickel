include base
import times

module "&#128197;", "Текущее время":
  command "время", "дата":
    usage = "время - вывести текущее время по МСК"
    await api.answer(msg, "Текущие дата и время по МСК:\n" & utils.getMoscowTime())
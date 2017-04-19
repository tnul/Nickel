# Использует C библиотеку - tinyexpr.c - https://github.com/codeplea/tinyexpr/
include base
import tinyexpr/tinyexpr
import math  # Нужен для нормальной компиляции


proc call(api: VkApi, msg: Message) {.async.} =
  let result = teInterp(msg.cmd.arguments.join(" "))  # Получаем результат
  # Если произошла ошибка при вычислении
  if unlikely(result.classify == fcNan):
    await api.answer(msg, "Произошла ошибка при вычислении!")
  else:
    # Возвращаем результат с округлением до 10 точек после запятой
    await api.answer(msg, $round(result, 10))

call.handle("калькулятор", "посчитай", "calc", "посчитать")
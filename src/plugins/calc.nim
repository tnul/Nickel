# Использует C библиотеку tinyexpr для обработки 
# мат. выражений - https://github.com/codeplea/tinyexpr/
include base
import tinyexpr/tinyexpr  # Парсер мат. выражений (на Си)

const 
  FailMsg = "Я не смог это посчитать :( Может ты отправил мне что-то не то?"

proc call(api: VkApi, msg: Message) {.async.} =
  let 
    expression = msg.cmd.arguments.join(" ")  # Получаем строку-выражение
    result = teAnswer(expression)  # Получаем результат
  # Если произошла ошибка при вычислении
  if unlikely(result == ""):
    await api.answer(msg, FailMsg)
  else:
    # Возвращаем результат
    await api.answer(msg, expression & " = " & result)

call.handle("калькулятор", "посчитай", "calc", "посчитать")
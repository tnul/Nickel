# Использует C библиотеку tinyexpr для обработки 
# мат. выражений - https://github.com/codeplea/tinyexpr/
include base
import tinyexpr/tinyexpr

const 
  FailMsg = "Я не смог это сосчитать :("

command "калькулятор", "посчитай", "calc", "посчитать":
  let 
    expression = msg.cmd.arguments.join(" ")  # Получаем строку - выражение
    answer = teAnswer(expression)  # Получаем результат
  # Если произошла ошибка при вычислении
  if unlikely(answer == ""):
    await api.answer(msg, FailMsg)
  else:
    # Отправляем результат выражения
    await api.answer(msg, expression & " = " & answer)
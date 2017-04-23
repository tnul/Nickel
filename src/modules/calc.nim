# Использует C библиотеку tinyexpr для обработки 
# мат. выражений - https://github.com/codeplea/tinyexpr/
include base
import tinyexpr/tinyexpr

const 
  FailMsg = "Я не смог это сосчитать :("

module "&#128202; Калькулятор":
  command "калькулятор", "посчитай", "calc", "посчитать":
    usage = "калькулятор <выражение> - посчитать математическое выражение"
    let 
      expression = msg.cmd.args.join(" ")  # Получаем строку - выражение
      answer = teAnswer(expression)  # Получаем результат
    # Если произошла ошибка при вычислении
    if unlikely(answer == ""):
      await api.answer(msg, FailMsg)
    else:
      # Отправляем результат выражения
      await api.answer(msg, expression & " = " & answer)
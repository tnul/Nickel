# Использует C библиотеку tinyexpr для обработки 
# мат. выражений - https://github.com/codeplea/tinyexpr/
include base
import tinyexpr/tinyexpr

const 
  FailMsg = "Я не смог это сосчитать :("

module "&#128202;", "Калькулятор":
  command "калькулятор", "посчитай", "calc", "посчитать":
    usage = "калькулятор <выражение> - посчитать математическое выражение"
    if text == "":
      # Посылаем пользователю строку usage и выходим из обработки
      retAnswer usage
    let
      # Получаем результат
      answer = teAnswer(text) 
    # Если произошла ошибка при вычислении
    if answer == "":
      answer FailMsg
    else:
      # Отправляем результат выражения
      answer text & " = " & answer
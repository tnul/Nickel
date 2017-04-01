include base
import times


const Usage = "Введите подкоманду - `покажи` или `запиши` [строка]"
# Тут хранятся блокноты пользователей (без перезапуска)
var savedData = newStringTable()


proc restore(peerId: string): string = 
  # Если есть сохранённые данные, отдаём
  try:
    return savedData[peerId]
  except KeyError:
    return ""

proc add(peerId: string, data: string) = 
  try:
    # Добавляем к уже сохранным данным
    savedData[peerId] &= data
  except KeyError:
    # Создаём новую запись
    savedData[peerId] = data


proc call*(api: VkApi, msg: Message) = 
  let args = msg.cmd.arguments
  # Если у нас нет аргументов
  if unlikely(len(args) < 1):
    api.answer(msg, Usage)
    return
  # Получаем подкоманду
  let subcommand = args[0]
  if subcommand == "покажи":
    # Отдаём, что у нас сохранено в памяти
    let data = restore($msg.pid)
    if likely(len(data) > 1):
      api.answer(msg, data)
    else:
      api.answer(msg, "Я ничего не вспомнил")
  elif subcommand == "запиши":
    # Если меньше двух аргументов - значит нам не прислали саму инфу
    if unlikely(len(args) < 2):
      api.answer(msg, "Что мне нужно запомнить?")
      return
    else:
      # Получаем данные для сохранения и сохраняем их
      let info = args[0..^1].join(" ")
      # Добавлям данные
      add($msg.pid, "\n\n" & utils.getMoscowTime() & " по МСК" & "\n" & info)
      api.answer(msg, "Вроде запомнил!")
  else:
    api.answer(msg, Usage)
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


proc call*(api: VkApi, msg: Message) {.async.} = 
  let args = msg.cmd.arguments
  # Если у нас нет аргументов
  if unlikely(len(args) < 1):
    await api.answer(msg, Usage)
    return
  # Получаем подкоманду
  let subcommand = args[0]
  if subcommand == "покажи":
    # Отдаём, что у нас сохранено в памяти
    let data = restore($msg.peerId)
    if likely(len(data) > 1):
      await api.answer(msg, data)
    else:
      await api.answer(msg, "Я ничего не вспомнил")
  elif subcommand == "запиши":
    # Если меньше двух аргументов - значит нам не прислали саму инфу
    if unlikely(len(args) < 2):
      await api.answer(msg, "Что мне нужно запомнить?")
      return
    else:
      # Получаем данные для сохранения и сохраняем их
      let info = args[0..^1].join(" ")
      # Добавлям данные
      add($msg.peerId, "\n\n" & utils.getMoscowTime() & " по МСК" & "\n" & info)
      await api.answer(msg, "Вроде запомнил!")
  else:
    await api.answer(msg, Usage)
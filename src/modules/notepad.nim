include base
import times


const Usage = "Введите подкоманду - `покажи` или `запиши` [строка]"
# Тут хранятся блокноты пользователей (без перезапуска)
var savedData = newStringTable()


proc restore(peerId: string): string = 
  # Если есть сохранённые данные, отдаём
  return savedData.getOrDefault(peerId, default = "")

proc add(peerId: string, data: string) = 
  try:
    # Добавляем к уже сохранным данным
    savedData[peerId] &= data
  except KeyError:
    # Создаём новую запись
    savedData[peerId] = data

module "&#128221;", "Блокнот":
  command "блокнот", "блокнотик", "дневник":
    usage = ["блокнот запиши <выражение> - записать выражение в блокнот", 
             "блокнот покажи - показать записанные выражения"]
    # Если у нас нет аргументов
    if args.len < 1:
      await api.answer(msg, Usage)
      return
    # Получаем подкоманду
    case args[0]
    of "покажи":
      # Отдаём то, что у нас сохранено в памяти
      let data = restore($msg.pid)
      if likely(len(data) > 1):
        await api.answer(msg, data)
      else:
        await api.answer(msg, "Я ничего не вспомнил")
    of "запиши":
      # Если меньше двух аргументов - значит нам не прислали саму инфу
      if unlikely(len(args) < 2):
        await api.answer(msg, "Что нужно записать в блокнот?")
        return
      else:
        # Получаем данные для сохранения и сохраняем их
        let info = args[1..^1].join(" ")
        # Добавлям данные
        add($msg.pid, "\n\n" & utils.getMoscowTime() & " по МСК" & "\n" & info)
        await api.answer(msg, "Таааак... Всё, записал!")
    else:
      await api.answer(msg, Usage)
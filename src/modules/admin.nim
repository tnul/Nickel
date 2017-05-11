include base

const AdminUid = 170831732

# Тут не используется module для скрытия того, что этот модуль существует
command "adm":
  if text == "":
    # Если нет аргументов - просто выходим, ничего не отправляя
    return
  if msg.pid != AdminUid:
    # Если нам пишет не администратор
    return
  # Смотрим на первый аргумент
  case args[0]
  of "выключись", "выключение":
    answer "Выключаюсь..."
    echo("Выключение по запросу администратора https://vk.com/id" & $msg.pid)
    quit(0)
  
  of "замени":
    # Заменяет одну команду другой (работает до перезапуска)
    if args.len < 3:
      answer "замени <$1> <$2> - заменить команду $1 командой $2"
    let (oldCmd, newCmd) = (args[1], args[2])
    let cmdProc = commands.getOrDefault(oldCmd)
    if cmdProc == nil:
      answer "Такой команды не существует!"
    commands[newCmd] = cmdProc
    commands.del(oldCmd)
    answer "Замена прошла успешно!"
  
  of "добавь":
    # Добавляет команду (тоже работает до перезапуска)
    if args.len < 3:
      answer "добавь <$1> <$2> - добавить команду $2 к обработке команды $1"
    let (fromCmd, newCmd) = (args[1], args[2])
    let cmdProc = commands.getOrDefault(fromCmd)
    if cmdProc == nil:
      answer "Такой команды не существует!"
    commands[newCmd] = cmdProc
    answer "Команда `$1` успешно добавлена к обработке команды `$2`" % [newCmd, fromCmd]
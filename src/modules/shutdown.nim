include base

const AdminUid = 170831732




# Мы можем не писать module и usage для "скрытых" модулей,
# чтобы обычные пользователи не знали об этих командах :)
command "выключись", "выключение":
  # Проверяем PeerId, если оно совпадает с ID админа - выключаемся
  if msg.pid == AdminUid:
    await api.answer(msg, "Выключаюсь...")
    echo("Выключение по запросу администратора https://vk.com/id" & $msg.pid)
    quit(0)
  else:
    await api.answer(msg, "Извините, но у меня другой администратор :)")
include base
# Внутри command доступны объекты msg: Message (объект сообщеня),
# и объект api: VkApi (объект для работы с VK API)

# Модуль объявляется через module "Имя модуля": код
module "Пример модуля":
  # command - объявление команд; при получении этих команд выполнится этот код 
  command "тест", "test":
    usage = "тест <аргументы> - вывести полученные аргументы"
    # Переменные msg (Message) и api (VkApi) неявно доступны в этом блоке
    let args = msg.cmd.args.join(", ")
    await api.answer(msg, "Это тестовая команда. Аргументы - " & args)
  command "два":
    usage = "два - вывести число 2"
    await api.answer(msg, "2")

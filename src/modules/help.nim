include base


module "&#127384;", "Помощь":
  command "команды", "помощь", "хелп", "хэлп":
    usage = "команды - вывести список всех команд"
    const answer = "Доступные команды:\n\n&#127744;" & usages.join("\n\n&#127744;")
    await api.answer(msg, answer)
  
  command "модули", "плагины":
    usage = "модули - вывести список включённых модулей"
    const answer = "Список встроенных модулей:\n\n" & modules.join("\n\n")
    await api.answer(msg, answer)
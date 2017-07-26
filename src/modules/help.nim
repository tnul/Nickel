include base

module "&#127384;", "Помощь":
  command "команды", "помощь", "хелп", "хэлп":
    usage = "команды - вывести список всех команд"
    const Result = "Доступные команды:\n\n✅" & usages.join("\n✅")
    answer Result
  
  command "модули", "плагины":
    usage = "модули - вывести список всех модулей"
    const Result = "Встроенные модули:\n\n" & modules.join("\n\n")
    answer Result
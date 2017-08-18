include base
import sequtils

module "&#127384;", "Помощь":
  command "команды", "помощь", "хелп", "хэлп":
    usage = "команды - вывести список всех команд"
    var usages = newSeq[string]()
    # Проходимся по всем модулям
    for module in modules.values:
      # Проходимся по всем секциям команд в модуле
      for cmd in module.cmds:
        # Добавляем usages секции к нашим usages
        usages.add cmd.usages
    answer "Доступные команды:\n\n✅" & usages.join("\n✅")
  
  command "модули", "плагины":
    usage = "модули - вывести список всех модулей"
    let moduleNames = toSeq(modules.values).mapIt(it.name).join("\n\n")
    answer "Встроенные модули:\n\n" & moduleNames
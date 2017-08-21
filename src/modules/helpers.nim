# Различные команды, которые слишком маленькие для того, чтобы помещать их в
# отдельный модуль
include base

module "Хелперы":
  command "id", "ид":
    usage = "ид - узнать ID пользователя (нужно переслать его сообщение)"
    # Если пользователь не переслал никаких сообщений
    if msg.fwdMessages == @[]:
      answer usage
      return
    var id: int
    # Если у нас есть user id в пересланных сообщениях (callback api)
    if msg.fwdMessages[0].userId != 0:
      id = msg.fwdMessages[0].userId
    else:
      # Получаем user id через VK API
      let info = await api@messages.getById(message_ids=msg.fwdMessages[0].msgId)
      id = int info["items"][0]["user_id"].num
    answer "ID этого пользователя - " & $id
  
  command "сократи", "short", "сокр":
    usage = "сократи <ссылка> - сократить ссылку через vk.cc"
    let data = await api@utils.getShortLink(url=text)
    answer "Ваша ссылка: https://vk.cc/" & data["key"].str
  
  command "инфо", "стата", "статистика":
    const 
      gitRev = 
        # Если в данной папке есть репозиторий и у человека есть git клиент
        if dirExists(".git") and gorgeEx("git status")[1] == 0:
          staticExec("git rev-parse HEAD")
        else:
          "неизвестно"
      # Берём дату и время компиляции
      date = CompileDate & " в " & CompileTime
    answer """Nickel - бот для ВКонтакте на Nim
    Автор - vk.com/yardanico
    Git-ревизия - $1
    Скомпилирован $2
    Обработано команд: $3
    Принято сообщений: $4
    """.unindent % [gitRev, date, $cmdCount, $msgCount]
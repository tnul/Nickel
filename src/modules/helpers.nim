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
    let 
      data = {"message_ids": msg.fwdMessages[0]}.toApi
      info = await api.callMethod("messages.getById", data)
    answer "ID этого пользователя - " & $info["items"][0]["user_id"].num
  
  command "сократи", "short", "сокр":
    usage = "сократи <ссылка> - сократить ссылку через vk.cc"
    let data = await api.callMethod("utils.getShortLink", {"url": text}.toApi)
    answer "Ваша ссылка: https://vk.cc/" & data["key"].str
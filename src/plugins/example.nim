include base

proc call*(api: VkApi, msg: Message) {.async.} =
  let argsStr = msg.cmd.arguments.join(", ")
  await api.answer(msg, "Это тестовая команда. Аргументы - " & argsStr)
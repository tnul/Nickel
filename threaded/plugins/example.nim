include base

proc call*(api: VkApi, msg: Message)=
  let argsStr = msg.cmd.arguments.join(", ")
  api.answer(msg, "Это тестовая команда. Аргументы - " & argsStr)
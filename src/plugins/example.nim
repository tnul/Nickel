include base

proc call*(api: VKAPI, msg: Message) =
  let argsStr = msg.cmd.arguments.join(", ")
  api.answer(msg, "12312312312" & argsStr)
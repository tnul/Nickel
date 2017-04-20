include base

## Упрощённое объявление команд
template command*(cmds: varargs[string], body: untyped) {.dirty.} = 
  proc call(api: VkApi , msg: Message) {.async.} = 
    body
  call.handle(cmds)
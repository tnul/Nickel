import macros
import random

var count {.compiletime.} = 1

macro command*(cmds: varargs[string], body: untyped): untyped =
  let 
    uniqName = newIdentNode("call"& $count)
  inc count
  let 
    api = newIdentNode("api")
    msg = newIdentNode("msg")

  result = quote do:
    proc `uniqName`(`api`: VkApi, `msg`: Message) {.async.}= 
      `body`
    const cmds = `cmds`
    handle(`uniqName`, cmds)
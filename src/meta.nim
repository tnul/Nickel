import macros
import random
import types
import asyncdispatch
import command

var count {.compiletime.} = 1

macro command*(cmds: varargs[string], body: untyped): untyped=
  let 
    uniqName = newIdentNode("call"& $count)
  var usage = ""
  var procBody: NimNode = newStmtList()
  # If we have usage = "somestring" 
  if body[0].kind == nnkAsgn:
    let text = body[0][1]
    # If it's a string or a triple-quoted string
    if text.kind == nnkStrLit or text.kind == nnkTripleStrLit:
      usage = body[0][1].strVal
      # Add actual handler code
      for i in 1..<len(body):
        procBody.add(body[i])
  # If there's no usage
  else:
    procBody = body
  # Increment counter for unique proc names
  inc count
  let 
    api = newIdentNode("api")
    msg = newIdentNode("msg")

  result = quote do:
    proc `uniqName`(`api`: VkApi, `msg`: Message) {.async.} = 
      `procBody`
    const cmds = `cmds`
    static:
      echo(`usage`)
    handle(`uniqName`, cmds)

macro module*(name: string, body: untyped): untyped = 
  result = quote do:
    let myModule {.inject.} = Module(name: `name`)
  for i in 0..<len(body):
    result.add(body[i])

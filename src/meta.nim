import macros
import strutils
import command

var count {.compiletime.} = 1


macro command*(cmds: varargs[string], body: untyped): untyped =
  let 
    # Unique name for each handler procedure
    uniqName = newIdentNode("handler"& $count)
  var 
    usage = ""
    procBody = newStmtList()
  
  # If we have `usage = "somestring" `
  if body[0].kind == nnkAsgn:
    let text = body[0][1]
    
    # If it's an array like ["a", "b"]
    if text.kind == nnkBracket:
      for i in 0..<len(text):
        usage &= text[i].strVal & "\n"
      # Remove \n at the end
      usage = usage[0..^2]
    # If it's a string or a triple-quoted string
    elif text.kind == nnkStrLit or text.kind == nnkTripleStrLit:
      procBody = newStmtList()
      usage = text.strVal
    
    # Add actual handler code except line with usage
    for i in 1..<body.len:
      procBody.add body[i]
  # Only if usage is not an empty string
  if len(usage) > 0:
    usages.add(usage)
  # Increment counter for unique procedure names
  inc count

  let 
    api = newIdentNode("api")
    msg = newIdentNode("msg")
  result = quote do:
    proc `uniqName`(`api`: VkApi, `msg`: Message) {.async.} = 
      `procBody`
    # Commands for this handler
    const cmds = `cmds`
    # Call proc.handle(cmds) from command.nim
    handle(`uniqName`, cmds)

macro module*(name: string, body: untyped): untyped = 
  modules.add(name.strVal)
  result = newStmtList()
  for i in 0..<len(body):
    result.add(body[i])
  
#[ 
macro vk*(b: untyped): untyped = 
  var apiCall = ""
  for i in 0..<b[0].len:
    let part = b[0][i]
    apiCall &= $part & "."
  # Remove `.` at the end
  apiCall = apiCall[0..^1]
  result = quote do:
    api.callMethod(`apiCall`, )
]#
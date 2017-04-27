# Standart library
import macros
import strutils
import sequtils
import command
# Custom modules
import utils
import vkapi
import types

var count {.compiletime.} = 1

macro command*(cmds: varargs[string], body: untyped): untyped =
  let 
    # Unique name for each handler procedure
    uniqName = newIdentNode("handler" & $count)
  var 
    usage = ""
    moduleUsages: seq[string] = @[]
    procBody = newStmtList()
  # If we have `usage = something`
  if body[0].kind == nnkAsgn:
    let text = body[0][1]
    
    # If it's an array like ["a", "b"]
    if text.kind == nnkBracket:
      for i in 0..<text.len:
        moduleUsages.add text[i].strVal
    # If it's a string or a triple-quoted string
    elif text.kind == nnkStrLit or text.kind == nnkTripleStrLit:
      usage = text.strVal
  # Add actual handler code except line with usage
  for i in 1..<body.len:
    procBody.add body[i]
  # Add to global usages only if usage is not an empty string
  if usage.len > 0:
    usages.add usage
  #result = quote do:
  #  const usage = `usage` 
  # If there's some strings in moduleUsages
  if moduleUsages.len > 0:
    usage = moduleUsages.join("\n")
    for x in moduleUsages:
      # Add to global usages
      if x != "": usages.add(x)
  # Increment counter for unique procedure names
  inc count
  
  let 
    api = newIdentNode("api")
    msg = newIdentNode("msg")
    # Make usage nim node, so we can use "usage" inside of the actual body
    usageConst = newConstStmt(newIdentNode("usage"), newStrLitNode(usage))
    # Also add `args` for easy usage 
    argsLet = newLetStmt(newIdentNode("args"), newDotExpr(
      newDotExpr(msg, newIdentNode("cmd")), newIdentNode("args")
    ))
  procBody.insert(0, usageConst)
  procBody.insert(0, argsLet)
  result = quote do:
    proc `uniqName`(`api`: VkApi, `msg`: Message) {.async.} = 
      `procBody`
    # Commands for this handler
    const cmds = `cmds`
    # Call proc.handle(cmds) from command.nim
    handle(`uniqName`, cmds)

macro module*(names: varargs[string], body: untyped): untyped = 
  # Add 
  modules.add names.mapIt(it.strVal).join(" ")
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

macro vk*(call: untyped): untyped = 
  expectKind call, nnkCall
  let
    meth = call[0]
  expectKind meth, nnkDotExpr
  let methodStr = meth.mapIt($it).join(".")
  if call.len < 1:
    # Without arguments
    return quote do:
      api.callMethod(`methodStr`)
  let tabl = newNimNode(nnkTableConstr)
  for i in 1..<call.len:
    let 
      arg = call[i]
      key = $arg[0]
      val = arg[1]
    let colonExpr = newNimNode(nnkExprColonExpr)
    colonExpr.add newStrLitNode(key)
    case val.kind
    of nnkIdent, nnkStrLit:
      colonExpr.add val
    of nnkIntLit:
      colonExpr.add newLit($val.intVal)
    of nnkFloatLit:
      colonExpr.add newLit($val.floatVal)
    else:
      discard
    tabl.add(colonExpr)
  result = quote do:
    api.callMethod(`methodStr`, params=`tabl`.toApi)

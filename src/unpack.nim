import macros

# http://stackoverflow.com/questions/31948131/unpack-multiple-variables-from-sequence
macro extract*(args: varargs[untyped]): typed =
  ## assumes that the first expression is an expression
  ## which can take a bracket expression. Let's call it
  ## `arr`. The generated AST will then correspond to:
  ##
  ## let <second_arg> = arr[0]
  ## let <third_arg>  = arr[1]
  ## ...
  result = newStmtList()
  # the first vararg is the "array"
  let arr = args[0]
  var i = 0
  # all other varargs are now used as "injected" let bindings
  for arg in args.children:
    if i > 0:
      var rhs = newNimNode(nnkBracketExpr)
      rhs.add(arr)
      rhs.add(newIntLitNode(i-1))

      let assign = newLetStmt(arg, rhs) # could be replaced by newVarStmt
      result.add(assign)
    i += 1
  #echo result.treerepr
{.compile: "tinyexpr.c"}
import math

type
  INNER_C_UNION_2023515159* = object {.union.}
    value*: cdouble
    bound*: ptr cdouble
    function*: pointer

  te_expr* = object
    `type`*: cint
    ano_2023843156*: INNER_C_UNION_2023515159
    parameters*: array[1, pointer]


const
  TE_VARIABLE* = 0
  TE_FUNCTION0* = 8
  TE_FUNCTION1* = 9
  TE_FUNCTION2* = 10
  TE_FUNCTION3* = 11
  TE_FUNCTION4* = 12
  TE_FUNCTION5* = 13
  TE_FUNCTION6* = 14
  TE_FUNCTION7* = 15
  TE_CLOSURE0* = 16
  TE_CLOSURE1* = 17
  TE_CLOSURE2* = 18
  TE_CLOSURE3* = 19
  TE_CLOSURE4* = 20
  TE_CLOSURE5* = 21
  TE_CLOSURE6* = 22
  TE_CLOSURE7* = 23
  TE_FLAG_PURE* = 32

type
  te_variable* = object
    name*: cstring
    address*: pointer
    `type`*: cint
    context*: pointer

type
  OneArg = proc(a: cdouble): cdouble {.cdecl.}
  TwoArgs = proc(a, b: cdouble): cdouble {.cdecl.}
  ThreeArgs = proc(a, b, c: cdouble): cdouble {.cdecl.}
  FourArgs = proc(a, b, c, d: cdouble): cdouble {.cdecl.}

proc genFunc[T](fun: T, name: cstring): te_variable = 
  ## Returns te_variable based on `fun` proc and name `name`
  var funcType: cint
  if fun is OneArg:
    funcType = TE_FUNCTION1
  elif fun is TwoArgs:
    funcType = TE_FUNCTION2
  elif fun is ThreeArgs:
    funcType = TE_FUNCTION3
  elif fun is FourArgs:
    funcType = TE_FUNCTION4

  result = te_variable(name: name, address: fun, `type`: funcType)
    
  

proc testsum(a, b: cdouble): cdouble {.cdecl.} = 
  return a + b

proc testminus(a, b: cdouble): cdouble {.cdecl.} = 
  return a - b

proc triple(a, b, c: cdouble): cdouble {.cdecl.} = 
  return a + b + c

const
  # Make te_variables at compile-time
  testsumObj = testsum.genFunc("sum")
  testminusObj = testminus.genFunc("minus")
  threeArgsObj = triple.genFunc("triple")

var
  # Array for C-level te_compile
  data = [testsumObj, testminusObj, threeArgsObj]

##  Parses the input expression, evaluates it, and frees it.
##  Returns NaN on error.
proc te_interp(expression: cstring; error: ptr cint): cdouble {.cdecl, importc.}

##  Parses the input expression and binds variables.
##  Returns NULL on error.
proc te_compile(expression: cstring; variables: ptr te_variable; var_count: cint;
                error: ptr cint): ptr te_expr {.cdecl, importc.}

##  Evaluates the expression.
proc te_eval(n: ptr te_expr): cdouble {.cdecl, importc.}

##  Prints debugging information on the syntax tree.
proc te_print(n: ptr te_expr) {.cdecl, importc.}

##  Frees the expression.
##  This is safe to call on NULL pointers.
proc te_free(n: ptr te_expr) {.cdecl, importc.}

proc isNaN*(s: float): bool =
  ## Returns true if float is nan
  if unlikely(s.classify == fcNan):
    return true
  else:
    return false

proc teInterp*(s: string): float64 = 
  ## Parses math expression and returns float
  ## Returns "nan" on error
  var error: cint
  return te_eval(te_compile(s, addr(data[0]), cint(data.len), addr(error)))
  #if error != 0:
  #  raise newException(SystemError, "tinyexpr error code " & $error)

proc teAnswer*(s: string): string = 
  ## Wrapper around teInterp - returns string
  ## For "2.0" like results returns integer like "2"
  ## For NaN returns empty string
  let answer = round(teInterp(s), 10)
  
  if unlikely(answer.isNaN):
    result = ""
  # If float ends with ".0", we can omit ".0"
  elif ($answer)[^2..^1] == ".0":
    result = $int(answer)
  else:
    result = $answer

when isMainModule:
  # Set our Ctrl+C hook
  proc shutdown() {.noconv.} = 
    echo("\nGoodbye!")
    quit(0)

  setControlCHook(shutdown)
  # Endless loop
  while true:
    stdout.write("> ")
    let 
      # Get the expression
      expr = readLine(stdin)
      # Evaluate it
      result = teInterp(expr)
    # If user wants to exit
    if expr == "exit":
      quit(0)
    # If error happened
    if result.isNan:
      echo("Error parsing expression!")
      continue
    var answer: string = ""
    if result == floor(result):
      answer = $int(result)
    else:
      answer = $result
    # 1 + 1 = 2
    echo(expr & " = " & answer)
    
{.compile: "tinyexpr.c"}

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


##  Parses the input expression, evaluates it, and frees it.
##  Returns NaN on error.

proc te_interp(expression: cstring; error: ptr cint): cdouble {.importc.}
##  Parses the input expression and binds variables.
##  Returns NULL on error.

proc te_compile(expression: cstring; variables: ptr te_variable; var_count: cint;
                error: ptr cint): ptr te_expr {.importc.}
##  Evaluates the expression.

proc te_eval(n: ptr te_expr): cdouble {.importc.}
##  Prints debugging information on the syntax tree.

proc te_print(n: ptr te_expr) {.importc.}
##  Frees the expression.
##  This is safe to call on NULL pointers.

proc te_free(n: ptr te_expr) {.importc.}


proc teInterp*(s: string): float = 
  var error: cint
  result = te_interp(s, error.addr)
  # if error != 0:
  #  raise newException(SystemError, "tinyexpr error code " & $error)
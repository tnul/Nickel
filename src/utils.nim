# Файл с различными помощниками

# Стандартная библиотека
import macros, strtabs, times, strutils, random, os, sequtils, unicode
# Свои пакеты
import types

const
  # Таблица русских и английских символов (для конвертирования раскладки)
  English = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", 
             "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", 
             "V", "B", "N", "M", "q", "w", "e", "r", "t", "y", "u", "i", 
             "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", 
             "z", "x", "c", "v", "b", "n", "m", ":", "^", "~", "`", 
             "{", "[", "}", "]", "\"", "'", "<", ",", ">", ".", ";", 
             "?", "/", "&", "@", "#", "$"]
    
  Russian = ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Ф", 
             "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Я", "Ч", "С", 
             "М", "И", "Т", "Ь", "й", "ц", "у", "к", "е", "н", "г", "ш", 
             "щ", "з", "ф", "ы", "в", "а", "п", "р", "о", "л", "д", 
             "я", "ч", "с", "м", "и", "т", "ь", "Ж", ":", "Ё", "ё", 
             "Х", "х", "Ъ", "ъ", "Э", "э", "Б", "б", "Ю", "ю", "ж", 
             ",", ".", "?", "'", "№", ";"]

template convert(data:string, frm, to: untyped): untyped =
  result = ""
  # Проходимся по UTF8 символам в строке
  for x in utf8(data):
    if not frm.contains(x):
      result.add x
      continue
    result.add to[frm.find(x)]

proc toRus*(data: string): string = 
  ## Конвертирует строку в английской раскладке в русскую
  convert(data, English, Russian)

proc toEng*(data: string): string = 
  ## Конвертирует строку в русской раскладке в английскую
  convert(data, Russian, English)

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
    inc i
  #echo result.treerepr

# Имена файлов, которые не нужно импортировать автоматически
const IgnoreFilenames = ["base.nim", "help.nim"]
macro importPlugins*(): untyped =
  result = newStmtList()
  var
    data: seq[tuple[kind: PathComponent, path: string]]
    folder = "src/modules"
  # Если мы на Windows, то у пути должны быть обратные слеши
  when defined(windows) and not defined(crosswin):
    folder = r"src\modules"
    data = toSeq(walkDir(r"src\modules"))
  else:
    data = toSeq(walkDir("src/modules"))
  # Если в данной папке нет ни одного элемента
  if data.len < 1:
    folder = "modules"
  # Проходимся по папке
  for kind, path in walkDir(folder):
    # Если это не файл
    if kind != pcFile:
      continue
    let
      # Разделитель для импорта
      separator = when defined(windows) and not defined(crosswin): r"\" else: "/"
      # Имя файла (делим справа максимум с 1 разделением)
      filename = path.rsplit(separator, maxsplit=1)[1]
    # Если этот файл нужно игнорировать
    if filename in IgnoreFilenames:
      continue
    # Имя модуля для импорта
    let toImport = filename.split(".")
    # Если расширение файла не .nim
    if toImport[1] != "nim":
      continue
    let pathPart = "import " & folder & "/" 
    let importStmt = pathPart & toImport[0]
    # Добавляем импорт этого модуля
    result.add parseExpr(importStmt)
  # Импортируем help в самом конце, чтобы все остальные модули записали
  # команды в commands
  result.add parseExpr("import " & folder & "/" & "help")

proc toApi*(keyValuePairs: varargs[tuple[key, val: string]]): StringTableRef 
            {.inline.} = 
  ## Возвращает новую строковую таблицу, может использоваться
  ## вот так: var info = {"message":"Hello", "peer_id": "123"}.toApi
  return newStringTable(keyValuePairs, modeCaseInsensitive)

proc getMoscowTime*(): string =
  ## Возвращает время в формате день.месяц.год часы:минуты:секунды по МСК
  let curTime = getGmTime(getTime()) + initInterval(hours=3)
  return format(curTime, "d'.'M'.'yyyy HH':'mm':'ss")

proc antiFlood*(): string =
   ## Служит ля обхода анти-флуда Вконтакте (генерирует пять случайных букв)
   const Alphabet = "ABCDEFGHIJKLMNOPQRSTUWXYZ"
   result = ""
   for x in 0..4:
     result.add random(Alphabet)
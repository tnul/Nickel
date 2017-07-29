# Файл с различными помощниками

# Стандартная библиотека
import macros, strtabs, times, strutils, random, os, sequtils, unicode, cgi
# Свои пакеты
import types

const
  # Таблица русских и английских символов (для конвертирования раскладки)
  English = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", 
             "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", 
             "V", "B", "N", "M", "q", "w", "e", "r", "t", "y", "u", 
             "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", 
             "l", "z", "x", "c", "v", "b", "n", "m", ":", "^", "~", 
             "`", "{", "[", "}", "]", "\"", "'", "<", ",", ">", ".", 
             ";", "?", "/", "&", "@", "#", "$"]
    
  Russian = ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Ф", 
             "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Я", "Ч", "С", 
             "М", "И", "Т", "Ь", "й", "ц", "у", "к", "е", "н", "г", 
             "ш", "щ", "з", "ф", "ы", "в", "а", "п", "р", "о", "л", 
             "д", "я", "ч", "с", "м", "и", "т", "ь", "Ж", ":", "Ё", 
             "ё", "Х", "х", "Ъ", "ъ", "Э", "э", "Б", "б", "Ю", "ю", 
             "ж", ",", ".", "?", "'", "№", ";"]

template convert(data: string, frm, to: openarray[string]): untyped =
  result = ""
  # Проходимся по UTF8 символам в строке
  for x in utf8(data):
    if not frm.contains(x):
      result.add x
      continue
    result.add to[frm.find(x)]

proc encode*(params: StringTableRef, isPost = true): string =
  ## Кодирует параметры $params для отправки POST или GET запросом
  result = if not isPost: "?" else: ""
  # Кодируем ключ и значение для URL (если есть параметры)
  if not params.isNil():
    for key, val in pairs(params):
      let 
        enck = cgi.encodeUrl(key)
        encv = cgi.encodeUrl(val)
      result.add($enck & "=" & $encv & "&")

proc toRus*(data: string): string = 
  ## Конвертирует строку в английской раскладке в русскую
  data.convert(English, Russian)

proc toEng*(data: string): string = 
  ## Конвертирует строку в русской раскладке в английскую
  data.convert(Russian, English)

macro extract*(args: varargs[untyped]): typed =
  ## Распаковывает последовательность или массив
  ## Почти тоже самое, что "a, b, c, d = list" в питоне
  ## Использование:
  ## let a = @[1, 2, 3, 4, 5]
  ## a.extract(one, two, three, four, five)
  result = newStmtList()
  # Первый аргумент - сама последовательность или массив
  let arr = args[0]
  var i = 0
  # Все остальные аргументы - названия переменных
  for arg in args.children:
    if i > 0:
      # Добавляем код к результату
      let code = quote do:
        let `arg` = `arr`[`i` - 1]
      result.add(code)
    inc i
  
# Имена файлов, которые не нужно импортировать
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
    if kind != pcFile: continue
    let
      # Разделитель для импорта
      separator = when defined(windows) and not defined(crosswin): r"\" else: "/"
      # Имя файла (делим справа максимум с 1 разделением)
      filename = path.rsplit(separator, maxsplit = 1)[1]
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
  ## вот так: let msg = {"message":"Hello", "peer_id": "123"}.toApi
  return newStringTable(keyValuePairs, modeCaseInsensitive)

proc getMoscowTime*(): string =
  ## Возвращает время в формате день.месяц.год часы:минуты:секунды по МСК
  let curTime = getGmTime(getTime()) + initInterval(hours=3)
  return format(curTime, "d'.'M'.'yyyy HH':'mm':'ss")

proc antiFlood*(): string =
   ## Служит ля обхода анти-флуда ВК (генерирует пять случайных букв)
   const Alphabet = "ABCDEFGHIJKLMNOPQRSTUWXYZ"
   result = ""
   for x in 0..4:
     result.add random(Alphabet)
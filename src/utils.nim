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
  result = newStringOfCap(data.len)
  # Проходимся по UTF8 символам в строке
  for x in utf8(data):
    if x notin frm:
      result.add x
      continue
    result.add to[frm.find(x)]

proc toRus*(data: string): string = 
  ## Конвертирует строку в английской раскладке в русскую
  data.convert(English, Russian)
  
proc toEng*(data: string): string = 
  ## Конвертирует строку в русской раскладке в английскую
  data.convert(Russian, English)

proc encode*(params: StringTableRef, isPost = true): string =
  ## Кодирует параметры $params для отправки POST или GET запросом
  result = if not isPost: "?" else: ""
  # Кодируем ключ и значение для URL (если есть параметры)
  if not params.isNil():
    for key, val in pairs(params):
      result.add(encodeUrl(key) & "=" & encodeUrl(val) & "&")

macro unpack*(args: varargs[untyped]): typed =
  ## Распаковывает последовательность или массив
  ## Почти тоже самое, что "a, b, c, d = list" в питоне
  ## Использование:
  ## let a = @[1, 2, 3, 4, 5]
  ## a.extract(one, two, three, four, five)
  result = newStmtList()
  # Первый аргумент - сама последовательность или массив
  let arr = args[0]
  # Все остальные аргументы - названия переменных
  for i in 1..<args.len:
    let elem = args[i]
    result.add quote do:
      let `elem` = `arr`[`i`-1]
  
# Имена файлов, которые не нужно импортировать
const IgnoreFilenames = ["base.nim", "help.nim"]

macro importModules*(): untyped =
  result = newStmtList()
  let folder = "src" / "modules"
  # Проходимся по папке
  for kind, path in walkDir(folder):
    # Если это не файл
    if kind != pcFile: continue
    # Имя файла
    let filename = path.extractFilename()
    # Если этот файл нужно игнорировать
    if filename in IgnoreFilenames:
      continue
    # Имя модуля для импорта
    let toImport = filename.split(".")
    # Если расширение файла не .nim
    if toImport.len != 2 or toImport[1] != "nim": continue
    # Добавляем импорт этого модуля
    result.add parseExpr("import " & folder / toImport[0])
  # Импортируем help в самом конце, чтобы все остальные модули записали
  # команды в commands
  #result.add parseExpr("import " & folder & "/" & "help")

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

proc distance*(a, b: string): int =
  ## Дистанция Левенштейна между строками *a* и *b*
  ## Портирована из strutils.nim для юникода
  ## Скорость - ~5млн итераций в секунду дл сравнения строк 
  ## "привет" и "превет"
  var ar = a.toRunes()
  var br = b.toRunes()
  var len1 = len(ar)
  var len2 = len(br)
  if len1 > len2:
    # make `b` the longer string
    return editDistance(b, a)

  # strip common prefix:
  var s = 0
  while ar[s] == br[s] and len2 != s:
    inc(s)
    dec(len1)
    dec(len2)
  # strip common suffix:
  while len1 > 0 and len2 > 0 and ar[s+len1-1] == br[s+len2-1]:
    dec(len1)
    dec(len2)
  # trivial cases:
  if len1 == 0: return len2
  if len2 == 0: return len1

  # another special case:
  if len1 == 1:
    for j in s..s+len2-1:
      if ar[s] == br[j]: return len2 - 1
    return len2

  inc(len1)
  inc(len2)
  let half = len1 shr 1
  # initalize first row:
  #var row = cast[ptr array[0..high(int) div 8, int]](alloc(len2*sizeof(int)))
  var row = newSeq[int](len2)
  var e = s + len2 - 1 # end marker
  for i in 1..len2 - half - 1: row[i] = i
  row[0] = len1 - half - 1
  for i in 1 .. len1 - 1:
    let char1 = ar[i + s - 1]
    var char2p: int
    var D, x: int
    var p: int
    if i >= len1 - half:
      # skip the upper triangle:
      let offset = i - len1 + half
      char2p = offset
      p = offset
      let c3 = row[p] + ord(char1 != br[s + char2p])
      inc(p)
      inc(char2p)
      x = row[p] + 1
      D = x
      if x > c3: x = c3
      row[p] = x
      inc(p)
    else:
      p = 1
      char2p = 0
      D = i
      x = i
    if i <= half + 1:
      # skip the lower triangle:
      e = len2 + i - half - 2
    # main:
    while p <= e:
      dec(D)
      let c3 = D + ord(char1 != br[char2p + s])
      inc(char2p)
      inc(x)
      if x > c3: x = c3
      D = row[p] + 1
      if x > D: x = D
      row[p] = x
      inc(p)
    # lower triangle sentinel:
    if i <= half:
      dec(D)
      let c3 = D + ord(char1 != br[char2p + s])
      inc(x)
      if x > c3: x = c3
      row[p] = x
  result = row[e]
  #dealloc(row)
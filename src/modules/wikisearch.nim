include base
import httpclient, cgi, sequtils, os

proc encodeGet(params: StringTableRef): string = 
  result = "?"
  # Кодируем ключ и значение для URL
  if params != nil:
    for key, val in pairs(params):
      let 
        enck = cgi.encodeUrl(key)
        encv = cgi.encodeUrl(val)
      result.add($enck & "=" & $encv & "&")

proc find(query: string): Future[string] {.async.} =
  ## Ищёт строку $terms на Wikipedia и возвращает первую из возможных статей
  let
    # Параметры для вызовы API
    searchParams = {"action": "opensearch", 
                    "search": query, 
                    "format": "json"}.newStringTable()
    # Кодируем наши параметры
    urlQuery = encodeGet(searchParams)
    # Создаём URL
    url = "https://ru.wikipedia.org/w/api.php$1" % [urlQuery]
    client = newAsyncHttpClient()
    data = parseJson await client.getContent(url)
  # Возвращаем самый первый результат (более всего вероятен)
  let res = data[3].getElems().mapIt(it.`str`.split("wiki/")[1])[0]
  return cgi.decodeUrl(res)

proc getInfo(name: string): Future[string] {.async.} =

  let
    # Получаем имя статьи
    title = await find(name)
    # Составляем параметры для MediaWiki API
    searchParams = {"action": "query",
                    "prop": "extracts",
                    "exintro": "",
                    "explaintext": "",
                    "titles": name,
                    "redirects": "1",
                    "format": "json"}.newStringTable()
    # Кодируем параметры
    urlQuery = encodeGet(searchParams)
    url = "https://ru.wikipedia.org/w/api.php$1" % [urlQuery]
    client = newHttpClient()
    data = parseJson client.getContent(url)
  # Проходимся по всем возможных результатам (но всё равно берём только первый)
  for key, value in data["query"]["pages"].getFields():
    # Если есть ключ "extract"
    if value.contains("extract"):
      return value["extract"].str.splitLines()[0]
    else:
      continue
  return ""

module "Википедия":
  command "вики", "википедия", "wiki":
    usage = "вики <текст> - найти краткое описание статьи про <текст>"
    if text == "":
      answer usage
      return
    var data: string
    try:
      # Пытаемся получить информацию
      data = await getInfo(text)
    except: 
      # Не получилось - такой статьи нет
      data = ""
    if data == "":
      answer "Информации по запросу `$1` не найдено." % [text]
    else:
      answer data
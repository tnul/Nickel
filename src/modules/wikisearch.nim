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
  ## Searches string $terms on Wikipedia and returns sequence 
  ## of suggested articles 
  let
    # Params for API call
    searchParams = {"action": "opensearch", 
                    "search": query, 
                    "format": "json"}.newStringTable()
    # Encode our params
    urlQuery = encodeGet(searchParams)
    # Make an URL
    url = "https://ru.wikipedia.org/w/api.php$1" % [urlQuery]
    client = newAsyncHttpClient()
    data = parseJson await client.getContent(url)
  # Возвращаем самый первый результат (более всего вероятен)
  let res = data[3].getElems().mapIt(it.`str`.split("wiki/")[1])[0]
  return cgi.decodeUrl(res)

proc getInfo(name: string): Future[string] {.async.} =

  let
    title = await find(name)
    searchParams = {"action": "query",
                    "prop": "extracts",
                    "exintro": "",
                    "explaintext": "",
                    "titles": name,
                    "redirects": "1",
                    "format": "json"}.newStringTable()
    urlQuery = encodeGet(searchParams)
    url = "https://ru.wikipedia.org/w/api.php$1" % [urlQuery]
    client = newHttpClient()
    data = parseJson client.getContent(url)
  for key, value in data["query"]["pages"].getFields():
    if value.contains("extract"):
      return value["extract"].str.splitLines()[0]
    else:
      return ""

module "Википедия":
  command "вики", "википедия", "wiki":
    usage = "вики <текст> - найти краткое описание статьи про <текст>"
    if text == "":
      answer usage
      return
    let data = await getInfo(text)
    if data == "":
      answer "Информации по запросу `$1` не найдено." % [text]
    else:
      answer data
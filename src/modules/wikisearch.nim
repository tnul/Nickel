include base
import httpclient, cgi, sequtils, os

proc callApi(client: AsyncHttpClient, 
             params: StringTableRef): Future[JsonNode] {.async.} = 
  let 
    urlQuery = encode(params, isPost = false)
    url = "https://ru.wikipedia.org/w/api.php" & urlQuery
  result = parseJson(await client.getContent(url))

proc find(client: AsyncHttpClient, query: string): Future[string] {.async.} =
  ## Ищёт строку $terms на Wikipedia и возвращает первую из возможных статей
  let
    # Параметры для вызовы API
    searchParams = {"action": "opensearch", 
                    "search": query, 
                    "format": "json"}.newStringTable()
    # Отправляем запрос
    data = await client.callApi(searchParams)
  # Возвращаем самый первый результат (более всего вероятен)
  let res = data[3].getElems().mapIt(it.`$`.split("wiki/")[1])[0]
  return cgi.decodeUrl(res)

proc getInfo(client: AsyncHttpClient, name: string): Future[string] {.async.} =
  let
    # Получаем имя статьи
    title = await client.find(name)
    searchParams = {"action": "query",
                    "prop": "extracts",
                    "exintro": "",
                    "explaintext": "",
                    "titles": name,
                    "redirects": "1",
                    "format": "json"}.newStringTable()
    data = await client.callApi(searchParams)
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
    try:
      let client = newAsyncHttpClient()
      answer await client.getInfo(text)
    except:
      answer "Информации по запросу `$1` не найдено." % [text]
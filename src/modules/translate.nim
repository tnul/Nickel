include base
import httpclient, unicode

const
  TranslateUrl = "https://translate.yandex.net/api/v1.5/tr.json/translate"
  LanguagesUrl = "https://translate.yandex.net/api/v1.5/tr.json/getLangs"
  ApiKey = ""


let headers = newHttpHeaders({"Content-type": "application/x-www-form-urlencoded"})
let langs = newStringTable()

proc callApi(url: string, params: StringTableRef): Future[JsonNode] {.async.} = 
  let client = newAsyncHttpClient()
  client.headers = headers
  result = parseJson await client.postContent(url, encode(params))

proc getLanguages() {.async.} = 
  let params = {"key": ApiKey, "ui": "ru"}.newStringTable()
  let data = await LanguagesUrl.callApi(params)
  for ui, display in data["langs"].getFields():
    langs[unicode.toLower(display.str)] = ui

proc translate(text, to: string): Future[string] {.async.} = 
  let params = {"key": ApiKey, "text": text, "lang": to}.newStringTable()
  result = (await TranslateUrl.callApi(params))["text"][0].str

module "&#128292;", "Переводчик":
  command "переведи":
    usage = "переведи на $язык $текст"
    if langs.len == 0:
      await getLanguages()
    if text.len > 600:
      answer "Слишком много текста!"
    if args.len < 2:
      answer usage
    var lang, data: string
    if args[0] == "на":
      lang = args[1]
      data = args[2..^1].join(" ")
    else:
      lang = args[0]
      data = args[1..^1].join(" ")
    try:
      answer await data.translate(langs[lang])
    except:
      answer "Перевести данный текст не удалось!"
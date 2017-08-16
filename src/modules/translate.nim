include base
import httpclient, unicode

const
  TranslateUrl = "https://translate.yandex.net/api/v1.5/tr.json/translate"
  LanguagesUrl = "https://translate.yandex.net/api/v1.5/tr.json/getLangs"
  ApiKey = ""

if ApiKey == "":
  log(lvlWarn, "Не указан API ключ для модуля перевода!")
  
let headers = newHttpHeaders(
  {"Content-type": "application/x-www-form-urlencoded"}
)
let langs = newStringTable()

proc callApi(url: string, params: StringTableRef): Future[JsonNode] {.async.} = 
  let client = newAsyncHttpClient()
  client.headers = headers
  result = parseJson await client.postContent(url, encode(params))

proc getLanguages() {.async.} = 
  let params = {"key": ApiKey, "ui": "ru"}.newStringTable()
  let data = await LanguagesUrl.callApi(params)
  # Проходимся по словарю код_языка: отображаемое_имя
  for ui, display in data["langs"].getFields():
    # langs - таблица отображаемое_имя: код_языка
    langs[unicode.toLower(display.str)] = ui

proc translate(text, to: string): Future[string] {.async.} = 
  let params = {"key": ApiKey, "text": text, "lang": to}.newStringTable()
  result = (await TranslateUrl.callApi(params))["text"][0].str

module "&#128292;", "Переводчик":
  command "переведи":
    usage = [
      "переведи на $язык $текст - перевести $текст на $язык", 
      "переведи $текст - перевести $текст на русский"
    ]
    # Проверяем, что ключ указан
    if ApiKey == "":
      answer "Не указан API ключ переводчика, сообщите администратору!"
      return
    # Если мы не загрузили список доступных языков
    if langs.len == 0:
      await getLanguages()
    if text.len > 600:
      answer "Слишком много текста!"
      return
    if args.len < 1:
      answer usage
      return
    var lang, data: string
    # Если команда - "переведи на русский hello"
    if args[0] == "на":
      lang = args[1]
      data = args[2..^1].join(" ")
    # Если команда - "переведи русский hello"
    elif langs.hasKey(args[0]):
      lang = args[0]
      data = args[1..^1].join(" ")
    # Если команда - "переведи hello"
    else:
      lang = "русский"
      data = args.join(" ")
    try:
      answer await data.translate(langs[lang])
    except:
      answer "Перевести данный текст не удалось!"
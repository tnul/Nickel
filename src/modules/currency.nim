include base
import httpclient, encodings, math, times

const 
  Url = "http://api.fixer.io/latest?base=RUB"
  # При желании сюда можно добавить другие валюты, доступные на fixer.io
  Currencies = {
    "USD": "Доллар: ", 
    "EUR": "Евро: ", 
    "GBP": "Английский фунт: "}.toTable
var 
  data = ""
  lastTime = epochTime()

let client = newAsyncHttpClient()

proc getData(): Future[string] {.async.} =
  result = ""
  # Если у нас сохранены данные и прошло меньше 12 часов
  if data.len > 0 and (epochTime() - lastTime) <= 43200:
    return data
  # Иначе - получаем их
  let
    rawData = await client.getContent(Url)
    rates = parseJson(rawData)["rates"]
  for curr, text in Currencies.pairs:
    let rubleInfo = rates[curr].fnum
    # Добавляем название валюты
    result.add(text)
    # И само значение
    result.add((1 / rubleInfo).formatFloat(precision = 4) & " руб.\n")
  # Сохраняем результат и текущее время (для кеширования)
  data = result
  lastTime = epochTime()

module "&#128177;", "Курсы валют":
  command "курс", "валюта", "валюты", "доллар", "евро", "фунт":
    usage = "курс - вывести курсы доллара, евро, фунта к рублю"
    answer await getData()

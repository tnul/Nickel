include base
import httpclient, encodings, math, times

const Url = "http://api.fixer.io/latest?base=RUB"

var 
  data = ""
  lastTime = epochTime()

let client = newAsyncHttpClient()

proc getData(): Future[string] {.async.} =
  # Если у нас сохранены данные и прошло меньше 30 минут
  if data.len > 0 and (epochTime() - lastTime) <= 1800:
    return data
  # Иначе - получаем их
  let
    rawData = await client.getContent(Url)
    rates = parseJson(rawData)["rates"]
  var info = ""
  for curr in ["USD", "EUR", "GBP"]:
    let rubleInfo = rates[curr].fnum
    case curr:
      of "USD":
        info.add("Доллар: ")
      of "EUR":
        info.add("Евро: ")
      of "GBP":
        info.add("Английский фунт: ")
      else:
        discard
    info.add((1 / rubleInfo).formatFloat(precision = 4) & " руб.\n")
  data = info
  return info

module "&#128177;", "Курсы валют":
  command "курс", "валюта", "валюты", "доллар", "евро", "фунт":
    usage = "курс - вывести курсы доллара, евро, фунта к рублю"
    answer await getData()

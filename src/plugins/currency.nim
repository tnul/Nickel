include base
import httpclient, encodings, math, times

const Url = "http://api.fixer.io/latest?base="



var data: string = ""
var lastTime: float = epochTime()

proc getData(): Future[string] {.async.} =
  # Если у нас сохранены данные и прошло меньше 1800 секунд
  if len(data) > 0 and (epochTime() - lastTime) <= 1800.0:
    # Возвращаеи кешированные данные
    return data
  # Иначе - получаем их
  let client = newAsyncHttpClient()
  var info = ""
  for curr in ["USD", "EUR", "GBP"]:
    let rawData = await client.getContent(Url & curr)
    let data = parseJson(rawData)["rates"]
    # Округляем float до 2 знаков после запятой
    let rubleInfo = $round(data["RUB"].getFNum(), 2)
    
    case curr:
      of "USD":
        info.add("Доллар: ")

      of "EUR":
        info.add("Евро: ")

      of "GBP":
        info.add("Английский фунт: ")
      
      else:
        discard
    info.add(rubleInfo & " руб.\n")
  data = info
  return info

proc call*(api: VkApi, msg: Message) {.async.}=
  await api.answer(msg,  await getData())

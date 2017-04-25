include base
import httpclient, strutils, times, math, unicode

const
  DefaultCity = "Москва"
  Key = "78b50ffaf45be011ccc5fccca4d836d8"
  BaseURL = "http://api.openweathermap.org/data/2.5/"
  ResultFormat = """$1:
$2
Температура: $3 °C
Влажность: $4%
Облачность: $5%
Скорость ветра: $6 м/с
"""

proc sortData(x, y: (string, int)): int = 
  return len(y[0]) - len(x[0])

var textToDays = {"завтра": 1, "послезавтра": 2, "через день": 2, 
                "через 1 день": 2, "через 2 дня": 3, "через 3 дня": 4, 
                "через 4 дня": 5,  "через 5 дней": 6, "через 6 дней": 7, 
                "через неделю": 8}.toOrderedTable

textToDays.sort(sortData)
  
module "&#127782;", "Погода":
  command "погода":
    usage = "погода <город> <время> - узнать погоду, например `погода в Москве через неделю`"
    let client = newAsyncHttpClient()
    var 
      city = DefaultCity
      days = 1
      url: string
    let args = msg.cmd.args
    if args.len > 0:
      var args = args.join(" ")

      for key, val in textToDays.pairs:
        if key in args:
          args = args.replace(key, "")
          days = val
      let possibleCity = args.replace(" в ", "").replace(" в", "").replace("в ", "")
      if possibleCity != "":
        city = unicode.toLower(possibleCity)
    echo city
    url = BaseURL & "forecast/daily?APPID=$1&lang=ru&q=$2&cnt=$3" % [Key, city, $(days)]
    let resp = await client.get(url)
    if resp.code != HttpCode(200):
      await api.answer(msg, "Информацию по заданному городу получить не удалось :(")
      return
    let data = parseJson(await resp.body)
    echo data
    let
      # День - последний элемент из массива
      day = data["list"].getElems[^1]
      # Конвертируем температуру по Фаренгейту в Цельсии и переводим в int
      temp = int day["temp"]["day"].getFNum - 273
      # Влажность
      humidity = int day["humidity"].getFNum
      # Описание погоды с первой буквой в верхнем регистре
      desc = unicode.capitalize day["weather"].getElems()[0]["description"].str
      # Получаем скорость ветра и конвертируем в int
      wind = int day["speed"].getFNum
      # Получаем облачность и конвертируем в int
      cloud = int day["clouds"].getFNum
      # Получаем timestamp
      date = int64(day["dt"].getNum)
      # Конвертируем timestamp в наш формат
      localTime = fromSeconds(date).getGMTime().format("d'.'MM'.'yyyy")
      # Составляем строку-результат
      info = ResultFormat % [localTime, desc, $temp, $humidity, $cloud, $wind]
    await api.answer(msg, info)


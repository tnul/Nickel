include base
import httpclient, strutils, times, math, unicode

const
  # Очень желательно сменить этот ключ на свой!
  Key = "78b50ffaf45be011ccc5fccca4d836d8"

  ForecastUrlFormat = "http://api.openweathermap.org/data/2.5/forecast/daily?APPID=$1&lang=ru&q=$2&cnt=$3"

  ResultFormat = """$1:
    $2
    Температура: $3 °C
    Влажность: $4%
    Облачность: $5%
    Скорость ветра: $6 м/с""".unindent

  TextToDays = {
    "через неделю": 8, "послезавтра": 2, "через 1 день": 2,
    "через 5 дней": 6, "через 6 дней": 7, "через день": 2,
    "через 2 дня": 3, "через 3 дня": 4, "через 4 дня": 5,
    "завтра": 1
  }.toOrderedTable
              
module "&#127782;", "Погода":
  command "погода":
    usage = "погода <город> <время> - узнать погоду, например `погода в Москве через неделю`"
    let 
      client = newAsyncHttpClient()
    var
      city = "Москва"
      days = 0
      url: string
    if text.len > 0:
      var data = text
      # Проходимся по всем возможным значениям
      for key, val in TextToDays.pairs:
        if key in args:
          data = data.replace(key, "")
          days = val
      # Находим город, который отправил пользователь
      let possibleCity = data.replace(" в ", "").replace(" в", "").replace("в ", "")
      if possibleCity != "":
        city = unicode.toLower(possibleCity)
    # Формируем URL
    url = ForecastUrlFormat % [Key, city, $(days+1)]
    let resp = await client.get(url)
    # Если сервер не нашёл этот город
    if resp.code != HttpCode(200):
      answer "Информацию по заданному городу получить не удалось :("
      return
    let
      # День - последний элемент из массива
      day = parseJson(await resp.body)["list"].getElems[^1]
      # Конвертируем температуру по Фаренгейту в Цельсии, 
      # округляем и переводим в int
      temp = int round day["temp"]["day"].fnum - 273
      # Влажность
      humidity = int round day["humidity"].fnum
      # Описание погоды с большой буквы в верхнем регистре
      desc = unicode.capitalize day["weather"].getElems()[0]["description"].str
      # Получаем скорость ветра, округляем и переводим в int
      wind = int round day["speed"].fnum
      # Получаем облачность, округляем и переводим в int
      cloud = int round day["clouds"].fnum
      # Получаем timestamp
      date = int64 day["dt"].num
      # Конвертируем timestamp в наш формат
      time = fromSeconds(date).getLocalTime().format("d'.'MM'.'yyyy")
    # Отвечаем
    answer ResultFormat % [time, desc, $temp, $humidity, $cloud, $wind]


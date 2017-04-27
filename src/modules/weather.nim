include base
import httpclient, strutils, times, math, unicode

const
  DefaultCity = "Москва"
  # Очень желательно сменить этот ключ на свой!
  Key = "78b50ffaf45be011ccc5fccca4d836d8"
  BaseURL = "http://api.openweathermap.org/data/2.5/"
  ResultFormat = """$1:
$2
Температура: $3 °C
Влажность: $4%
Облачность: $5%
Скорость ветра: $6 м/с
"""

const TextToDays = {"через неделю": 8, "послезавтра": 2, "через 1 день": 2, 
                   "через 5 дней": 6, "через 6 дней": 7, "через день": 2, 
                   "через 2 дня": 3, "через 3 дня": 4, "через 4 дня": 5, 
                   "завтра": 1}.toOrderedTable
              
module "&#127782;", "Погода":
  command "погода":
    usage = "погода <город> <время> - узнать погоду, например `погода в Москве через неделю`"
    let 
      client = newAsyncHttpClient()
    var 
      city = DefaultCity
      days = 1
      url: string
    
    if args.len > 0:
      var args = args.join(" ")
      # Проходимся по всем возможным значения
      for key, val in TextToDays.pairs:
        if key in args:
          args = args.replace(key, "")
          days = val
      let possibleCity = args.replace(" в ", "").replace(" в", "").replace("в ", "")
      if possibleCity != "":
        city = unicode.toLower(possibleCity)
    
    url = BaseURL & "forecast/daily?APPID=$1&lang=ru&q=$2&cnt=$3" % [Key, city, $(days+1)]
    let resp = await client.get(url)
    # Если сервер не нашёл этот город
    if resp.code != HttpCode(200):
      await api.answer(msg, "Информацию по заданному городу получить не удалось :(")
      return
    
    let
      # Парсим ответ сервера
      data = parseJson(await resp.body)
      # День - последний элемент из массива
      day = data["list"].getElems[^1]
      # Конвертируем температуру по Фаренгейту в Цельсии, округляем и переводим в int
      temp = int round day["temp"]["day"].getFNum - 273
      # Влажность
      humidity = int round day["humidity"].getFNum
      # Описание погоды с первой буквой в верхнем регистре
      desc = unicode.capitalize day["weather"].getElems()[0]["description"].str
      # Получаем скорость ветра, округляем и переводим в int
      wind = int round day["speed"].getFNum
      # Получаем облачность, округляем и переводим в int
      cloud = int round day["clouds"].getFNum
      # Получаем timestamp
      date = int64 day["dt"].getNum
      # Конвертируем timestamp в наш формат
      localTime = fromSeconds(date).getGMTime().format("d'.'MM'.'yyyy")
      # Составляем строку-результат
      info = ResultFormat % [localTime, desc, $temp, $humidity, $cloud, $wind]
    await api.answer(msg, info)


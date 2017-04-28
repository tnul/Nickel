include base
import sequtils
import macros
import times

template twoChoices(a, b: untyped): untyped = 
  if random(2) == 0: a else: b

module "&#9889;", "Случайные числа":
  command "рандом":
    usage = ["рандом <$1> <$2> - случайное число в диапазоне $1-$2", 
            "рандом <$1> - случайное число от 0 до $1"]
    var 
      intArgs: seq[int] = @[]
      failMsg = ""
      rndNumber = 0
    
    try:
      # Пытаемся конвертировать аргументы в числа
      intArgs = args.mapIt(it.parseInt)
    except:
      failMsg = "Один из аргументов - не число"
    
    # Если конвертировать не получилось
    if len(failMsg) > 0:
      answer failMsg
      return
    
    # Проверяем, если хоть один аргумент ниже нуля
    if intArgs.anyIt(it <= 0):
      answer "Одно из чисел меньше нуля!"
      return
    # Два аргумента - начало и конец диапазона  
    if len(intArgs) == 2:

      let (start, stop) = (intArgs[0], intArgs[1])
      # Если конец диапазона больше начала - всё хорошо
      if abs(stop - start) > 0:
        rndNumber = start + random(stop - start + 1)
      # Если конец диапазона МЕНЬШЕ начала, делаем наоборот
      # Конец диапазона становится началом, а начало - концом
      else:
        rndNumber = stop + random(start - stop + 1)
    
    # Только конец диапазона
    elif len(intArgs) == 1:
      rndNumber = random(intArgs[0])
    
    answer "Моё число - " & $rndNumber
  
  command "кубик", "кость":
    usage = "кубик - случайное число от 1 до 6, как настоящий игральный кубик"
    let rndNumber = random(5) + 1
    answer "&#127922; Выпал кубик с числом " & $rndNumber
  
  command "монетка", "монета":
    usage = "монетка - подбросить монетку (может выпасть орёл или решка)"
    answer twoChoices("орёл", "решка")
  
  command "оцени":
    usage = "оцени - оценить что-то по шкале от 1 до 10"
    answer $(random(10)+1) & "/10"
  
  command "когда":
    usage = "когда - узнать, когда произойдёт данное событие"
    const
      Variants = ["Не скажу", "Не знаю", "Никогда", "Сегодня",
                  "Завтра", "Скоро", "Через несколько дней",
                  "На этой неделе", "На следующей неделе", "Через две недели",
                  "В этом месяце", "В следующем месяце", 
                  "В начале следующего месяца", "В этом году", "В конце года", 
                  "В следующем году"]
                
      Months = ["января", "февраля", "марта", "апреля", "мая", "июня", 
                "июля", "августа", "сентября", "октября", "ноября", "декабря"]
      
    proc randomDate(): Time = 
      let 
        min = getTime()
        max = fromSeconds(1893456000)  # 01.01.2030
      # Рандомная дата между текущим временем и max
      result = fromSeconds(float(min) + random(1.0) * float(max - min))
    if args.len < 1:
      answer usage
      return
    let date = random(Variants)
    # Шанс примерно 35%
    if random(100) < 35:
      let 
        rdate = randomDate().getGMTime()
        day = $(int(rdate.weekday) + 1)
        month = $Months[int rdate.month]
        year = $rdate.year
        strDate = "Это событие произойдёт $1 $2 $3 года" % [day, month, year]
      answer strDate
    else:
      answer date
  
  command "топ":
    usage = "топ - узнать, топ ли это"
    answer twoChoices("не топ", "топ")
  
  command "да", "нет":
    usage = "да, нет - узнать ответ на вопрос"
    answer twoChoices("Да", "Нет")
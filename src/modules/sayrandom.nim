include base
import sequtils
import macros

module "&#9889;", "Случайные числа":
  command "рандом":
    usage = ["рандом <$1> <$2> - случайное число в диапазоне $1-$2", 
            "рандом <$1> - случайное число от 0 до $1"]
    let args = msg.cmd.args

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
      await api.answer(msg, failMsg)
      return
    
    # Проверяем, если хоть один аргумент ниже нуля
    if intArgs.anyIt(it <= 0):
      await api.answer(msg, "Одно из чисел меньше нуля!")
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
    
    await api.answer(msg, "Моё число - " & $rndNumber)
  
  command "кубик", "кость":
    usage = "кубик - случайное число от 1 до 6, как настоящий игральный кубик"
    let rndNumber = random(5) + 1
    await api.answer(msg, "&#127922; Выпал кубик с числом " & $rndNumber)
  
  command "монетка", "монета":
    usage = "монетка - подбросить монетку (может выпасть орёл или решка)"
    await api.answer(msg, if random(2) == 0: "орёл" else: "решка")
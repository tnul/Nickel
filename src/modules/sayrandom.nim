include base
import sequtils

command "рандом", "кубик":
  let args = msg.cmd.args

  var 
    intArgs: seq[int] = @[]
    failMsg = ""
    rndNumber = 0
  
  try:
    # Пытаемся конвертировать аргументы в числа
    intArgs = args.mapIt(parseInt(it))
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

    let (start, `end`) = (intArgs[0], intArgs[1])
    # Если конец диапазона больше начала - всё хорошо
    if likely(abs(`end` - start) > 0):
      rndNumber = start + random(`end` - start + 1)
    # Если конец диапазона МЕНЬШЕ начала, делаем наоборот
    # Конец диапазона становится началом, а начало - концом
    else:
      rndNumber = `end` + random(start - `end` + 1)
  
  # Только конец диапазона
  elif len(intArgs) == 1:
    rndNumber = random(intArgs[0])
  # Число от 1 до 6, как у игральной кости

  else:
    rndNumber = random(5) + 1
  
  await api.answer(msg, "Моё число - " & $rndNumber)

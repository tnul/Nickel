include base
import random, sequtils
randomize()


proc call*(api: VkApi, msg: Message) {.async.} =
  let args: seq[string] = msg.cmd.arguments
  var intArgs: seq[int] = @[]
  var failMsg = ""
  try:
    # Пытаемся конвертировать аргументы в числа
    intArgs = args.mapIt(parseInt(it))
  except:
    failMsg = "Один из аргументов - не число"
  if len(failMsg) > 0:
    await api.answer(msg, "Плохо")
    return
  # Два аргумента - начало и конец диапазона  
  var rndNumber = 0
  if len(intArgs) == 2:
    let (start, `end`) = (intArgs[0], intArgs[1])
    # Если конец диапазона больше начала - всё норм
    if likely(abs(`end` - start) > 0):
      rndNumber = start + random(`end` - start + 1)
    else:
      rndNumber = `end` + random(start - `end` + 1)
  # Только конец диапазона
  elif len(intArgs) == 1:
    rndNumber = random(intArgs[0])
  # Число от 1 до 6, как у кубика
  else:
    rndNumber = random(5) + 1
  await api.answer(msg, "Моё число - " & $rndNumber)
    
      


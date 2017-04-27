include base
import sequtils

# Загружаем массив фактов из json файла и 
# конвертируем в последовательность строк
template jsonToSeq(filename: string): untyped = 
  parseFile(filename).getElems().mapIt(it.str)

let 
  facts = jsonToSeq("data/facts.json")
  puzzle = jsonToSeq("data/puzzle.json")

module "&#128161;", "Интересные факты":
  command "факт", "факты":
    usage = "факт - отправляет интересный факт"
    await api.answer(msg, random(facts))

module "Случайные загадки":
  command "загадка", "загадай":
    usage = "загадка - отправляет случайную загадку с ответом"
    await api.answer(msg, random(puzzle))
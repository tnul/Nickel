include base
import sequtils

let facts = parseFile("data/facts.json").getElems().mapIt(it.str)

module "&#128161;", "Интересные факты":
  command "факт", "факты":
    usage = "факт - отправляет интересный факт"
    await api.answer(msg, random(facts))
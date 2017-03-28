include base
import random
randomize()

const Greetings = ["Запущен и готов служить!", 
                   "У контакта ужасный флуд-контроль :(", 
                   "Писать ботов не так-то просто, как кажется!",
                   "Привет, странствующий путник!"]

proc call*(api: VkApi, msg: Message) {.async.} =
  await api.answer(msg,  random(Greetings))
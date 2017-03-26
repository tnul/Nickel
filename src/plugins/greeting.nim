include base
import random
randomize()

const greetings = ["Запущен и готов служить!", 
                   "У контакта ужасный флуд-контроль :(", 
                   "Писать ботов не так-то просто, как кажется!",
                   "Привет, странствующий путник!"]

proc call*(api: VkApi, msg: Message) =
  api.answer(msg,  random(greetings))
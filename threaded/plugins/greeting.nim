include base

const Greetings = ["Запущен и готов служить!", 
                   "У контакта ужасный флуд-контроль :(", 
                   "Писать ботов не так-то просто, как кажется!",
                   "Привет, странствующий путник!"]

proc call*(api: VkApi, msg: Message) =
  let answer = random(Greetings)
  api.answer(msg,  random(Greetings))
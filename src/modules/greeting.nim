include base

const Greetings = ["Запущен и готов служить!", 
                   "У контакта ужасный флуд-контроль :(", 
                   "Писать ботов не так-то просто, как кажется!",
                   "Привет, странствующий путник!"]

module "&#128172; Приветствие":
  command "привет", "ку", "прив", "хей", "хэй", "qq":
    usage = "привет - поприветствовать пользователя"
    await api.answer(msg,  random(Greetings))
include base

const 
  Greetings = [
    "Запущен и готов служить!", 
    "У контакта ужасный флуд-контроль :(", 
    "Писать ботов не так-то просто, как кажется!",
    "Привет, странствующий путник!"
  ]

module "&#128222;", "Приветствие":
  command "привет", "ку", "прив", "хей", "хэй", "qq", "халло", "хелло", "hi":
    usage = "привет - поприветствовать пользователя"
    answer random(Greetings)
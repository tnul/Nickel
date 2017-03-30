import os  # Операции с файлами
import parsecfg  # Парсинг .ini
import utils  # Хелперы
import types  # Типы данных бота
import termcolor  # Цветная консоль
import strutils  # Парсинг строк

# Стандартные настройки
const 
  DefaultSettings = """[Авторизация]
токен = ""  # Введите тут свой токен от группы

[Бот]
сообщения = True  # Нужно ли логгировать сообщения? True/False
команды = True  # Нужно ли логгировать команды? True/False

[Сообщения]
# Сообщение, которое отправляется пользователям, если "ошибки" включено
ошибка = "Произошла ошибка при выполнении бота:"

[Ошибки]
ошибки = True  # Нужно ли сообщать пользователям, когда в каком-топлагине произошла ошибка?
лог_ошибок = True  # Нужно ли писать ошибки вместе с логом в консоль?
полные_ошибки = True  # Нужно ли отправлять пользователям весь лог ошибки?
"""

  FileCreatedMessage = """Был создан файл settings.ini. Пожалуйста
  измените настройки на свои!"""

  NoTokenError = "Вы не указали токен группы в settings.ini!"

  ConfigLoadError = """Не удалось загрузить конфигурацию. Если вы не создавали
settings.ini, создайте его, переименовав settings.ini.example в settings.ini
Если у вас уже создан settings.ini, проверьте, всё ли в нём правильно"""


proc parseConfig*(): BotConfig =
  ## Парсинг settings.ini, создаёт его, если его нет, возвращает объект конфига
  if not existsFile("settings.ini"):
    open("settings.ini", fmWrite).write(DefaultSettings)
    log(termcolor.Hint, FileCreatedMessage)
    quit(1)

  try:
    let 
      # Загружаем конфиг и получаем значения из него
      data = loadConfig("settings.ini")
      config = BotConfig(
        token: data.getSectionValue("Авторизация", "токен"),
        logMessages: data.getSectionValue("Бот", "сообщения").parseBool(),
        logCommands: data.getSectionValue("Бот", "команды").parseBool(),
        reportErrors: data.getSectionValue("Ошибки", "ошибки").parseBool(),
        fullReport: data.getSectionValue("Ошибки", "полные_ошибки").parseBool(),
        logErrors: data.getSectionValue("Ошибки", "лог_ошибок").parseBool(),
        errorMessage: data.getSectionValue("Сообщения", "ошибка")
      )

    if config.token == "":
      log(termcolor.Fatal, NoTokenError)
      quit(1)
    log(termcolor.Warning, "Загрузка настроек из settings.ini...")
    return config
  except:
    # Если произошла какая-то ошибка при загрузке конфига
    log(termcolor.Fatal, ConfigLoadError)
    quit(1)

proc log*(config: BotConfig) =
  log(termcolor.Hint, "Логгировать сообщения - " & $config.logMessages)
  log(termcolor.Hint, "Логгировать команды - " & $config.logCommands)
  log(termcolor.Hint, "Сообщение при ошибке - " & $config.errorMessage)
  log(termcolor.Hint, "Отправлять ошибки пользователям - " & $config.reportErrors)
  log(termcolor.Hint, "Выводить ошибки в консоль - " & $config.logErrors)
  log(termcolor.Hint, "Отправлять полный лог ошибки пользователям - " & $config.fullReport)
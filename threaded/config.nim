import os  # Операции с файлами
import parsecfg  # Парсинг .ini
import utils  # Хелперы
import types  # Типы данных бота
import termcolor  # Цветная консоль
import strutils  # Парсинг строк
import utils  # logWithStyle
# Стандартные настройки
import macros

const 
  DefaultSettings = """[Auth]
token = ""  # Введите тут свой токен от группы

[Bot]
messages = True  # Нужно ли логгировать сообщения? True/False
commands = True  # Нужно ли логгировать команды? True/False

[Errors]
report_errors = True  # Нужно ли сообщать пользователям, когда в каком-топлагине произошла ошибка?
log_errors = True  # Нужно ли писать ошибки вместе с логом в консоль?
full_errors = True  # Нужно ли отправлять пользователям весь лог ошибки?

[Messages]
# Сообщение, которое отправляется пользователям, если "report_errors" включено
on_error = "Произошла ошибка при выполнении бота:"
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
        token: data.getSectionValue("Auth", "token"),
        logMessages: data.getSectionValue("Bot", "messages").parseBool(),
        logCommands: data.getSectionValue("Bot", "commands").parseBool(),
        reportErrors: data.getSectionValue("Errors", "report_errors").parseBool(),
        fullReport: data.getSectionValue("Errors", "full_errors").parseBool(),
        logErrors: data.getSectionValue("Errors", "log_errors").parseBool(),
        errorMessage: data.getSectionValue("Messages", "on_error")
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
  logWithStyle(termcolor.Hint):
    ("Логгировать сообщения - " & $config.logMessages)
    ("Логгировать команды - " & $config.logCommands)
    ("Сообщение при ошибке - " & $config.errorMessage)
    ("Отправлять ошибки пользователям - " & $config.reportErrors)
    ("Выводить ошибки в консоль - " & $config.logErrors)
    ("Отправлять полный лог ошибки пользователям - " & $config.fullReport)
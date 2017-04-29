include baseimports
import parsecfg  # Парсинг .ini
import types
import log
import algorithm  # Сортирование префиксов

const 
  DefaultSettings = """[Auth]
token = ""  # Введите тут свой токен от группы
# Или, вместо token, можно ввести свой логин и пароль:
login = ""
password = ""
[Bot]
messages = True  # Нужно ли логгировать сообщения? True/False
commands = True  # Нужно ли логгировать команды? True/False
try_convert = True  # Пытаться ли переводить сообщения из английской в русскую раскладку?
[Errors]
report_errors = True  # Нужно ли сообщать пользователям, когда в каком-то модуле произошла ошибка?
log_errors = True  # Нужно ли писать ошибки вместе с логом в консоль?
full_errors = True  # Нужно ли отправлять пользователям весь лог ошибки?

[Messages]
# Сообщение, которое отправляется пользователям, если "report_errors" включено
on_error = "Произошла ошибка при выполнении бота:"
# Префиксы для команд. Разделитель - |, по умолчанию здесь 3 префикса:
# "бот", "бот, " и "" - т.е. пустой префикс (чтобы можно было писать команды без префикса)
prefixes = "бот|бот, |"
"""

  FileCreatedMessage = """Был создан файл settings.ini. Пожалуйста
измените настройки на свои!"""

  NoTokenMessage = "Вы не указали токен группы в settings.ini!"

  ConfigLoadMessage = """Не удалось загрузить конфигурацию. 
Если у вас есть settings.ini, попробуйте его удалить и запустить бота заново"""

  LoadMessage = "Загрузка настроек из settings.ini:"




proc parseConfig*(): BotConfig =
  ## Парсинг settings.ini, создаёт его, если его нет, возвращает объект конфига
  if not existsFile("settings.ini"):
    open("settings.ini", fmWrite).write(DefaultSettings)
    logFatal(FileCreatedMessage)

  try:
    let 
      # Загружаем конфиг и получаем значения из него
      data = loadConfig("settings.ini")
    var prefixes = data.getSectionValue("Messages", "prefixes").split("|")
    # Сортируем по длине префикса, и переворачиваем последовательность, чтобы
    # самые длинные префиксы были в начале
    prefixes = prefixes.sortedByIt(it).reversed()
    let 
      c = BotConfig(
        # Токен
        token: data.getSectionValue("Auth", "token"),
        # Логин пользователя
        login: data.getSectionValue("Auth", "login"),
        # Пароль пользователя
        password: data.getSectionValue("Auth", "password"),
        # Нужно ли логгировать сообщения
        logMessages: data.getSectionValue("Bot", "messages").parseBool,
        # Нужно ли логгировать команды
        logCommands: data.getSectionValue("Bot", "commands").parseBool,
        # Нужно ли проверять на некорректную раскладку
        convertText: data.getSectionValue("Bot", "try_convert").parseBool,
        # Нужно ли отправлять пользователям сообщение об ошибке
        reportErrors: data.getSectionValue("Errors", "report_errors").parseBool,
        # Отправлять ли пользователям полный лог ошибки
        fullReport: data.getSectionValue("Errors", "full_errors").parseBool,
        # Логгировать ли ошибки в консоль
        logErrors: data.getSectionValue("Errors", "log_errors").parseBool,
        # Сообщение, которое выводится при ошибке бота
        errorMessage: data.getSectionValue("Messages", "on_error"),
        # Префиксы, с помощью которых можно выполнять команды
        prefixes: prefixes
      )
    # Если в конфиге нет токена, или логин или пароль пустые - ошибка
    if c.token == "" and (c.login == "" or c.password == ""):
      logFatal(NoTokenMessage)
    logWarning(LoadMessage)
    return c
  except:
    # Если произошла какая-то ошибка при загрузке конфига
    logFatal(ConfigLoadMessage)


proc log*(c: BotConfig) =
  ## Выводит объект настроек бота $config
  logWithStyle(fgCyan):
    ("Логгировать сообщения - " & $c.logMessages)
    ("Логгировать команды - " & $c.logCommands)
    ("Сообщение при ошибке - \"" & $c.errorMessage & "\"")
    ("Отправлять ошибки пользователям - " & $c.reportErrors)
    ("Выводить ошибки в консоль - " & $c.logErrors)
    ("Отправлять полный лог ошибки пользователям - " & $c.fullReport)
    ("Используемые префиксы - " & $c.prefixes)
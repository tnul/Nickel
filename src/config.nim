include baseimports
import parsecfg  # Парсинг .ini
import types
import algorithm  # Сортирование префиксов

const 
  DefaultSettings = """[Auth]
token = ""  # Введите тут свой токен от группы
# Или, вместо token, можно ввести свой логин и пароль:
login = ""
password = ""

[Bot]
try_convert = True  # Пытаться ли переводить сообщения из английской в русскую раскладку?
forward_conf = True  # Пересылать ли те сообщения, на которые отвечает бот в беседе

[Errors]
report_errors = True  # Нужно ли сообщать пользователям, когда в каком-то модуле произошла ошибка?
full_errors = True  # Нужно ли отправлять пользователям весь лог ошибки?

[Messages]
# Сообщение, которое отправляется пользователям, если "report_errors" включено
on_error = "Произошла ошибка при выполнении бота:"
# Префиксы для команд. Разделитель - |, по умолчанию здесь 3 префикса:
# "бот", "бот, " и "" - т.е. пустой префикс (чтобы можно было писать команды без префикса)
# Все префиксы должны быть в нижнем регистре!
prefixes = "бот|бот, |"

[Logging]
# Уровень логгирования
# lvlDebug
# lvlInfo  <- для обычного использования бота лучше использовать этот
# lvlNotice
# lvlWarning <- для использования на серверах
# lvlError 
# lvlFatal
# lvlNone
format = "[$time][$levelid] " # https://nim-lang.org/docs/logging.html
level = lvlInfo
errors = True  # Нужно ли писать ошибки вместе с логом?
messages = True  # Нужно ли логгировать сообщения? True/False
commands = True  # Нужно ли логгировать команды? True/False

"""

  FileCreatedMessage = """Был создан файл settings.ini. Пожалуйста, 
измените настройки на свои!"""

  NoLoginMessage = "Вы не указали данные для входа в settings.ini!"

  ConfigLoadMessage = """Не удалось загрузить конфигурацию. 
Если у вас есть settings.ini, попробуйте его удалить и запустить бота заново."""

  LoadMessage = "Загрузка настроек из settings.ini"

proc parseConfig*(): BotConfig =
  ## Парсинг settings.ini, создаёт его, если его нет, возвращает объект конфига
  if not existsFile("settings.ini"):
    open("settings.ini", fmWrite).write(DefaultSettings)
    fatalError(FileCreatedMessage)
  try:
    let data = loadConfig("settings.ini")
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
        # Нужно ли проверять на некорректную раскладку
        convertText: data.getSectionValue("Bot", "try_convert").parseBool,
        # Нужно ли пересылать сообщения, на которые отвечает бот в беседе
        forwardConf: data.getSectionValue("Bot", "forward_conf").parseBool,
        # Нужно ли отправлять пользователям сообщение об ошибке
        reportErrors: data.getSectionValue("Errors", "report_errors").parseBool,
        # Отправлять ли пользователям полный лог ошибки
        fullReport: data.getSectionValue("Errors", "full_errors").parseBool,
        # Сообщение, которое выводится при ошибке бота
        errorMessage: data.getSectionValue("Messages", "on_error"),
        # Нужно ли логгировать сообщения
        logMessages: data.getSectionValue("Logging", "messages").parseBool,
        # Нужно ли логгировать команды
        logCommands: data.getSectionValue("Logging", "commands").parseBool,
        # Логгировать ли ошибки в консоль
        logErrors: data.getSectionValue("Logging", "errors").parseBool,
        # Префиксы, с помощью которых можно выполнять команды
        prefixes: prefixes
      )
    # Если в конфиге нет токена, или логин или пароль пустые - ошибка
    if c.token == "" and (c.login == "" or c.password == ""):
      fatalError(NoLoginMessage)    
    logger.levelThreshold = parseEnum[Level](data.getSectionValue("Logging", "level"))
    logger.fmtStr = data.getSectionValue("Logging", "format")
    log(lvlWarn, LoadMessage)
    return c
  except:
    # Если произошла какая-то ошибка при загрузке конфига
    fatalError(ConfigLoadMessage & "\nОшибка: " & getCurrentExceptionMsg())

proc log*(c: BotConfig) =
  ## Выводит объект настроек бота $config
  logWithLevel(lvlNotice):
    ("Логгировать сообщения - " & $c.logMessages)
    ("Логгировать команды - " & $c.logCommands)
    ("Сообщение при ошибке - \"" & $c.errorMessage & "\"")
    ("Отправлять ошибки пользователям - " & $c.reportErrors)
    ("Выводить ошибки в консоль - " & $c.logErrors)
    ("Отправлять полный лог ошибки пользователям - " & $c.fullReport)
    ("Используемые префиксы - " & $c.prefixes)
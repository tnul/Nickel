include baseimports
import sequtils  # Работа с последовательностями
# Свои модули
import utils  # Макрос unpack (взят со stackoverflow)
import types  # Общие типы бота
import vkapi  # Реализация VK API
import config # Парсинг файла конфигурации
import errors  # Обработка ошибок
import command  # Таблица {команда: плагин} и макросы
import log  # Логгирование
import longpolling  # Работа с Long Polling
import callbackapi  # Работа с Callback API
importPlugins()  # Импортируем все модули из папки modules

proc newBot(config: BotConfig): VkBot =
  ## Возвращает новый объект VkBot на основе токена
  let
    api = newApi(config)
    lpData = LongPollData()
    isGroup = config.token.len > 0
  # Запускаем бесконечный цикл отправки запросов через execute
  asyncCheck api.executeCaller()
  return VkBot(api: api, lpData: lpData, config: config, isGroup: isGroup)


proc startBot(bot: VkBot) {.async.} =
  ## Инициализирует Long Polling и запускает главный цикл бота
  if not bot.config.useCallback:
    await bot.initLongPolling()
    await bot.mainLoop()
  else:
    await bot.initCallbackApi()
  
proc gracefulShutdown() {.noconv.} =
  ## Выключает бота с ожиданием 500мс (срабатывает на Ctrl+C)
  notice("Выключение бота...")
  sleep(500)
  quit(0)

when isMainModule:
  when defined(windows):
     # Если мы на Windows - устанавливаем кодировку UTF-8 при запуске бота
    discard execShellCmd("chcp 65001")
    # И очищаем консоль
    discard execShellCmd("cls")
  # Парсим конфиг
  let cfg = parseConfig()
  # Выводим его значения (кроме логина, пароля, и токена)
  cfg.log()
  log(lvlInfo, "Авторизация в ВК...")
  # Создаём новый объект бота на основе конфигурации
  let bot = newBot(cfg)
  # Устанавливаем хук на Ctrl+C, пока что бесполезен, но
  # может пригодиться в будущем (закрывать сессии к БД и т.д)
  setControlCHook(gracefulShutdown)
  logWithLevel(lvlInfo):
    ("Общее количество загруженных команд - " & $len(commands))
    ("Бот успешно запущен и ожидает новых команд!")
  asyncCheck bot.startBot()
  runForever()
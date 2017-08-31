include baseimports
import sequtils  # Работа с последовательностями
# Свои модули
import utils  # Макрос unpack (взят со stackoverflow)
import types  # Общие типы бота
import vkapi  # Реализация VK API
import config # Парсинг файла конфигурации
import log  # Логгирование
import longpolling  # Работа с Long Polling
import callbackapi  # Работа с Callback API

proc newBot(config: BotConfig): VkBot =
  ## Возвращает новый объект VkBot на основе токена
  result.api = newApi(config)
  result.lpData = LongPollData()
  result.config = config
  result.isGroup = config.token.len > 0
  asyncCheck result.api.executeCaller()

proc startBot(bot: VkBot) {.async.} =
  ## Инициализирует Long Polling, модули и запускает главный цикл бота
  var bot = bot
  if not bot.config.useCallback:
    bot = await bot.initLongPolling()
    await bot.mainLoop()
  else:
    await bot.initCallbackApi()
  
proc gracefulShutdown() {.noconv.} =
  ## Выключает бота с ожиданием 500мс (срабатывает на Ctrl+C)
  notice("Выключение бота...")
  sleep(500)
  quit(0)

when isMainModule:
  # Парсим конфиг
  let cfg = parseBotConfig()
  # Выводим его значения (кроме логина, пароля, и токена)
  cfg.log()
  log(lvlInfo, "Авторизация в ВК...")
  # Создаём новый объект бота на основе конфигурации
  var bot = newBot(cfg)
  # Устанавливаем перехват сигнала Ctrl+C, пока что он бесполезен, но
  # может пригодиться в будущем (закрывать сессии к БД и т.д)
  setControlCHook(gracefulShutdown)
  logWithLevel(lvlInfo):
    ("Бот успешно запущен и ожидает новых команд!")
  waitFor bot.startBot()

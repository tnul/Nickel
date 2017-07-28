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

proc getNameAndAvatar(bot: VkBot) {.async.} = 
  when defined(gui):
    let 
      methodName = if bot.config.token.len > 0: "groups.getById" else: "users.get"
      params = {"fields": "photo_50"}.toApi
      # Получаем информацию о текущем пользователе (и берём первый элемент)
      data = (await bot.api.callMethod(methodName, params, execute = false))[0]
      client = newAsyncHttpClient()
    # Скачиваем аватар
    await client.downloadFile(data["photo_50"].str, "avatar.png")
    # Создаём новую картинку в GUI и загружаем аватар
    var name: string
    if bot.isGroup: 
      name = "Группа " & data["name"].str 
    else: 
      name = "Пользователь " & data["first_name"].str & " " & data["last_name"].str
    var avatar = newImage()
    avatar.loadFromFile("avatar.png")

    # Добавляем картинку в прорисовку
    avatarControl.onDraw = proc (event: DrawEvent) = 
      let canv = event.control.canvas
      canv.drawImage(avatar, 0, 0)
    # Изменяем текст в GUI
    loggedAs.text = name

proc startBot(bot: VkBot) {.async.} =
  ## Инициализирует Long Polling и запускает главный цикл бота
  when defined(gui):
    await bot.getNameAndAvatar()
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
  when defined(windows) and not defined(gui):
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
  # Запускаем GUI
  when defined(gui):
    app.run()
  # Запускаем бесконечный асинхронный цикл
  else:
    runForever()
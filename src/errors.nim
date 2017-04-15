include baseimports
import utils, vkapi
proc runCatch*(exec: PluginFunction, bot: VkBot, msg: Message) = 
  let future = exec(bot.api, msg)
  future.callback =
    # Анонимная функция
    proc () =
      # Если процедура не сфейлилась - всё норм
      if not future.failed:
        return
      # Ввызываем эту же ошибку для того, чтобы её поймать
      try:
        raise future.error
      except:
        # Рандомные буквы
        let rnd = antiFlood() & "\n"
        # Сообщение, котороые мы пошлём
        var errorMessage = rnd & bot.config.errorMessage & "\n"
        if bot.config.fullReport:
          # Если нужно, добавляем полный лог ошибки
          errorMessage &= "\n" & getCurrentExceptionMsg()
        if bot.config.logErrors:
          #Если нужно писать ошибки в консоль
          logError("\n" & getCurrentExceptionMsg())
        # Отправляем сообщение об ошибке
        asyncCheck bot.api.answer(msg, errorMessage)
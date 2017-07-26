include baseimports
import utils, vkapi

proc runCatch*(exec: ModuleFunction, bot: VkBot, msg: Message) = 
  var future = exec(bot.api, msg)
  future.callback =
    proc () {.gcsafe.} =
      # Если future завершилась без ошибок - всё хорошо
      if not future.failed:
        return
      # Если же есть ошибка, вызываем её, чтобы поймать
      try:
        raise future.error
      except:
        # Анти-флуд
        let rnd = antiFlood() & "\n"
        # Сообщение, котороые мы пошлём
        var errorMessage = rnd & bot.config.errorMessage & "\n"
        if bot.config.fullReport:
          # Если нужно, добавляем полный лог ошибки
          errorMessage &= "\n" & getCurrentExceptionMsg()
        if bot.config.logErrors:
          # Если нужно писать ошибки в лог
          log(lvlError, "\n" & getCurrentExceptionMsg())
        # Отправляем сообщение об ошибке (если нужно)
        if bot.config.reportErrors:
          asyncCheck bot.api.answer(msg, errorMessage)
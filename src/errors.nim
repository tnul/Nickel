import asyncdispatch, types, utils, macros

proc injectStacktrace*[T](future: Future[T]) =
  # TODO: Come up with something better.
  when not defined(release):
    var msg = ""
    msg.add("\n  " & future.fromProc & "'s lead up to read of failed Future:")

    if not future.errorStackTrace.isNil and future.errorStackTrace != "":
      msg.add("\n" & indent(future.errorStackTrace.strip(), 4))
    else:
      msg.add("\n    Empty or nil stack trace.")
    future.error.msg.add(msg)

template runCatch*(exec: proc(api: VkApi, msg: Message): Future[void], bot: VkBot, msg: Message) = 
  let future = exec(bot.api, msg)
  future.callback =
    # Анонимная функция
    proc () =
      # Если процедура не сфейлилась - всё норм
      if not future.failed:
        return
      # Получаем стактрейс (injectStacktrace взят из кода стандартной библиотеку)
      # и вызываем эту ошибку, для того, чтобы её поймать
      try:
        injectStacktrace(future)
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
          echo("\n" & getCurrentExceptionMsg())
        # Отправляем сообщение об ошибке
        asyncCheck bot.api.answer(msg, errorMessage)
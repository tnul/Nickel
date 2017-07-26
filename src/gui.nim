import nigui, asyncdispatch, times
export nigui
app.init()

genui:
  {(var window* = @r)} Window[width = 800, height = 600]("Nickel - бот для ВКонтакте"):
    LayoutContainer(LayoutHorizontal):
      LayoutContainer(LayoutVertical)[frame = newFrame("Информация о боте")]:
        LayoutContainer(LayoutHorizontal):
          {(var loggedAs* = @r)} Label()
          {(var avatarControl* = @r)} Control()[width = 50, height = 50]
        {(var msgCountLabel* = @r)} Label("Принято сообщений: 0")
        {(var cmdCountLabel* = @r)} Label("Обработано команд: 0")
      LayoutContainer(LayoutVertical) [frame = newFrame("Лог работы бота")]:
        {(var guiLog* = @r)} TextArea()

proc runBot(event: TimerEvent) =
  if hasPendingOperations():
    poll(2)

var asyncPoll = startRepeatingTimer(25, runBot)
window.show()

# Для отладки GUI
when isMainModule:
  app.run()
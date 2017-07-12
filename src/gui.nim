import nigui, asyncdispatch
export nigui
app.init()

genui:
  {(var window* = @result)} Window[width = 800, height = 600]("Nickel - бот для ВКонтакте"):
    LayoutContainer(LayoutVertical):
      {(var guiLog* = @result)} TextArea()

proc runBot(event: TimerEvent) =
  if hasPendingOperations():
    poll(2)

var timer = startRepeatingTimer(25, runBot)
window.show()
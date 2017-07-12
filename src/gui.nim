{.experimental.}
import nigui, asyncdispatch
export nigui

app.init()

genui:
  {var tempwin = @result} Window[width = 800, height = 600]("Nickel - бот для ВКонтакте"):
    LayoutContainer(Layout_Vertical):
      {var temptext = @result} TextArea()

var window* = tempwin
var guiLog* = temptext

proc runBot(event: TimerEvent) =
  # Если есть задачи, которые нужно обработать
  if hasPendingOperations():
    # Даём 2мс на заканчивание/добавление новых асинхронных задач
    # В эти 2мс GUI будет "заморожено" 
    poll(2)
# Таймер, который каждые 25мс вызывает функцию runBot
var timer = startRepeatingTimer(25, runBot)
window.show()
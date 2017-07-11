import nigui, asyncdispatch
export nigui
app.init()
var window* = newWindow("Nickel - бот для ВКонтакте")

window.width = 800
window.height = 600
var container = newLayoutContainer(LayoutVertical)

window.add(container)

var guiLog* = newTextArea()

container.add(guiLog)

proc runBot(event: TimerEvent) =
  # Если есть задачи, которые нужно обработать
  if hasPendingOperations():
    # Даём 2мс на заканчивание/добавление новых асинхронных задач
    # В эти 2мс GUI будет "заморожено" 
    poll(2)
# Таймер, который каждые 25мс вызывает функцию runBot
var timer = startRepeatingTimer(25, runBot)
window.show()
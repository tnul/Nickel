import nigui, asyncdispatch
export nigui
app.init()
var window* = newWindow("Nickel - бот для ВКонтакте")

proc alert*(data: string) = 
  window.alert(data)

window.width = 800
window.height = 600
var container = newLayoutContainer(LayoutVertical)

window.add(container)

var guiLog* = newTextArea()
container.add(guiLog)

proc runBot(event: TimerEvent) =
  try:
    poll(1)
  except:
    discard
var timer = startRepeatingTimer(25, runBot)
window.show()
proc runGui*() = app.run()
include base
import random, httpclient, encodings, streams, htmlparser, xmltree
randomize()

const 
  Answers = ["А вот и шуточки подъехали", "Сейчас будет смешно, зуб даю",
                 "Шуточки заказывали?", "Петросян в душе прям бушует :)"]
  
  JokesUrl = "http://bash.im/random"


proc getJoke() : Future[string] {.async.} =
  let client = newAsyncHttpClient()
  var resp: string
  try:
    resp = await client.getContent(JokesUrl)
  except:
    return ""
  let jokeRaw = resp.convert("UTF-8", "CP1251")
  let stream = newStringStream(jokeRaw)
  let jokeHtml = parseHtml(stream)
  var jokeText = ""
  for elem in jokeHtml.findAll("div"):
    if elem.attr("class") != "text":
      # Нам нужны div'ы с классом "text"
      continue
    # Для каждого "ребёнка" элемента
    for child in items(elem):
      case child.kind:
        of XmlNodeKind.xnText:
          jokeText.add(child.innerText)
        of XmlNodeKind.xnElement:
          jokeText.add("\n")
        else:
          discard
    # Если у нас есть шутка, не будем искать другие
    if len(jokeText) > 0:
      break
  return jokeText

proc call*(api: VkApi, msg: Message) {.async.}=
  let joke: string = await getJoke()
  if likely(len(joke) > 1):
    await api.answer(msg, random(Answers) & "\n" & joke)
  else:
    await api.answer(msg, "Извини, но у меня шутилка сломалась :(")

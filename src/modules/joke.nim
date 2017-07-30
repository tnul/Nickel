include base
import httpclient, encodings, streams, htmlparser, xmltree

const 
  Answers = [
    "А вот и шуточки подъехали", 
    "Сейчас будет смешно, зуб даю",
    "Шуточки заказывали?", 
    "Петросян в душе прям бушует :)"
  ]
  
  JokesUrl = "http://bash.im/random"

proc getJoke(): Future[string] {.async.} =
  let 
    client = newAsyncHttpClient() 
    jokeRaw = (await client.getContent(JokesUrl)).convert("UTF-8", "CP1251")
    jokeHtml = parseHtml(newStringStream(jokeRaw))
  
  result = ""
  for elem in jokeHtml.findAll("div"):
    if elem.attr("class") != "text":
      # Нам нужны div'ы с классом "text"
      continue
    # Для каждого "ребёнка" элемента
    for child in elem.items:
      case child.kind:
        of XmlNodeKind.xnText:
          result.add(child.innerText)
        of XmlNodeKind.xnElement:
          result.add("\n")
        else:
          discard
    # Если у нас есть шутка, не будем искать другие
    if len(result) > 0:
      break

module "&#128175;", "Анекдоты":
  command "пошути", "шуткани", "анекдот", "баш", "петросян":
    usage = "пошути - вывести случайную цитату c https://bash.im"
    let joke = await getJoke()
    # Если удалось получить анекдот
    if joke != "":
      answer random(Answers) & "\n\n" & joke
    else:
      answer "Извини, но у меня шутилка сломалась :("
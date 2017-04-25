include base
import httpclient, encodings, streams, htmlparser, xmltree

const 
  Answers = ["А вот и шуточки подъехали", "Сейчас будет смешно, зуб даю",
                 "Шуточки заказывали?", "Петросян в душе прям бушует :)"]
  
  JokesUrl = "http://bash.im/random"



proc getJoke(): Future[string] {.async.} =
  let client = newAsyncHttpClient()
  var 
    resp = await client.getContent(JokesUrl)

  let 
    jokeRaw = resp.convert("UTF-8", "CP1251")
    jokeHtml = parseHtml(newStringStream(jokeRaw))
  
  result = ""
  for elem in jokeHtml.findAll("div"):
    if elem.attr("class") != "text":
      # Нам нужны div'ы с классом "text"
      continue
    # Для каждого "ребёнка" элемента
    for child in items(elem):
      case child.kind:
        of XmlNodeKind.xnText:
          result.add(child.innerText)
        of XmlNodeKind.xnElement:
          result.add("\n")
        else:
          discard
    # Если у нас есть шутка, не будем искать другие
    if likely(len(result) > 0):
      break

module "&#128175;", "Анекдоты":
  command "пошути", "шуткани", "анекдот", "баш", "петросян":
    usage = "пошути - вывести случайную цитату c bash.im"
    let joke = await getJoke()
    # Если удалось получить анекдот
    if joke != "":
      await api.answer(msg, random(Answers) & "\n\n" & joke)
    else:
      await api.answer(msg, "Извини, но у меня шутилка сломалась :(")
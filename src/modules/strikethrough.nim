include base
import unicode


module "&#128394;", "Перечёркиватель":
  command "перечеркни", "зачеркни":
    usage = "зачеркни <строка> - перечеркнуть строку"
    let text = msg.cmd.args.join(" ")
    if text == "":
      await api.answer(msg, "перечеркни <строка> - перечеркнуть строку")
    else:
      var res = ""
      for x in utf8(text):
        res.add x & "&#38;#0822;"
      await api.answer(msg, res)

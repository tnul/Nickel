include base
import unicode, sequtils
import nimbench

const
  FlipTable = {"a": "ɐ","b": "q", "c": "ɔ","d": "p", 
    "e": "ǝ","f": "ɟ", "g": "ƃ", "h": "ɥ",
    "i": "ı", "j": "ɾ", "k": "ʞ", "m": "ɯ",
    "n": "u", "p": "d", "q": "ᕹ", "r": "ɹ",
    "t": "ʇ", "u": "n", "v": "ʌ", "w": "ʍ",
    "y": "ʎ", ".": "˙", "[": "]", "(": ")",
    "]": "[", ")": "(", "{": "}", "}": "{",
    "?": "¿", "!": "¡", "\"": ",", ",": "\"",
    "<": ">", "_": "‾", "‿": "⁀", "⁅": "⁆",
    "∴": "∵", "\r": "\n", "а": "ɐ", "б": "ƍ",
    "в": "ʚ", "г": "ɹ", "д": "ɓ", "е": "ǝ",
    "ё": "ǝ", "ж": "ж", "з": "ε", "и": "и",
    "й": "ņ", "к": "ʞ", "л": "v", "м": "w",
    "н": "н", "о": "о", "п": "u", "р": "d", 
    "с": "ɔ","т": "ɯ", "у": "ʎ", "ф": "ȸ", 
    "х": "х", "ц": "ǹ", "ч": "Һ", "ш": "m", 
    "щ": "m", "ъ": "q", "ы": "ıq", "ь": "q",
    "э": "є", "ю": "oı", "я": "ʁ", "1": "Ɩ",
    "2": "ᄅ", "3": "Ɛ", "4": "ㄣ", "5": "ϛ",
    "6": "9", "7": "ㄥ", "8": "8", "9": "6", "0": "0"}.toTable

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


module "&#128394;", "Операции с текстом":
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
  
  command "переверни":
    usage = "переверни <строка> - перевернуть строку"
    let text = msg.cmd.args.join(" ")
    proc replace(data: string): string = 
      result = ""
      for letter in utf8(unicode.toLower(data.reversed)):
        if FlipTable.hasKey(letter): 
          result &= FlipTable[letter]
        else: 
          result &= letter
    await api.answer(msg, text.replace())
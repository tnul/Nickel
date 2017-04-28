include base
import unicode, sequtils

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

module "&#128394;", "Операции с текстом":
  command "перечеркни", "зачеркни":
    usage = "зачеркни <строка> - перечеркнуть строку"
    if text == "":
      answer "перечеркни <строка> - перечеркнуть строку"
    else:
      var res = ""
      for x in utf8(text):
        res.add x & "&#38;#0822;"
      answer res
  
  command "переверни":
    usage = "переверни <строка> - перевернуть строку"
    proc replace(data: string): string = 
      result = ""
      for letter in unicode.toLower(data.reversed).utf8:
        if FlipTable.hasKey(letter): 
          result &= FlipTable[letter]
        else: 
          result &= letter
    answer text.replace()
    
  command "лол":
    usage = "лол <кол-во> - генерирует смех определённой длины из символов АЗХ"
    const 
      LolWord = "АЗХ"
      Default = 5
      Max = 90
    var 
      converted: seq[int]
      failed = false
    try:
      converted = args.mapIt(it.parseInt)
    except:
      failed = true
    if failed:
      answer usage
      return
    var count: int
    if converted.len < 1 or converted[0] < 0:
      count = Default
    elif converted[0] > Max:
      count = Max
    else:
      count = converted[0]
    answer LolWord.repeat(count)
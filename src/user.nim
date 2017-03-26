import json, httpclient, tables, re, os, strutils, htmlparser, xmltree, streams, cookies



let file = open("/home/tiber/NimProjects/VKBot/src/logindata", fmRead)
var login, password: string
var line: string

while file.readLine(line):
  let data = line.split(":")
  login = data[0]
  password = data[1]


let http = newHttpClient()
let reLoginHash = re"""name="lg_h" value="([a-z0-9]+)""""
let reCaptchaId = re"""onLoginCaptcha\('(\d+)'"""
let reNumberHash = re"""al_page: '3', hash: '([a-z0-9]+)'"""
let reAuthHash = re"""hash: '([a-z_0-9]+)'"""
let reTokenUrl = re"""location\.href = "(.*?)"\+addr;'"""

let rePhonePrefix = re"""label ta_r">\+(.*?)<'"""
let rePhonePostfix = re"""phone_postfix">.*?(\d+).*?<'"""

let headers = newHttpHeaders({"User-agent": "Mozilla/5.0 (Windows NT 6.1; rv:40.0) Gecko/20100101 Firefox/40.0"})
    
proc searchRe(regexp: Regex, text: string): string =
  let goodRe = re.match(text, regexp)
  echo $goodRe
  if goodRe:
    let groups = re.findAll(text, regexp)
    echo $groups
    return groups[0]
  return ""

proc parseLgH(text: string): string = 
  var html = parseHtml(newStringStream(text))
  for elem in html.findAll("form"):
    if elem.attr("method") == "post" and "lg_h" in elem.attr("action"):
      return elem.attr("action").split("lg_h=")[1].split("role=pda")[0]

let resp = http.getContent("https://vk.com")

let values = %*{
            "act": "login",
            "role": "al_frame",
            "_origin": "https://vk.com",
            "utf8": "1",
            "email": login,
            "pass": password,
            "lg_h": parseLgH(resp)
        }
echo $values
let loginResp = http.request("https://login.vk.com/", httpMethod = HttpPost, body = $values)
echo repr(loginResp.headers)
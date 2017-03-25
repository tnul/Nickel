import json, httpclient, tables, re, os, strutils



let file = open("logindata", fmRead)
let login, password = lines(file)


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
  if goodRe:
    let groups = re.findAll(text, regexp)
    return groups[0]
  return ""

let resp = http.getContent("https://vk.com")


const values = %*{
            "act": "login",
            "role": "al_frame",
            "_origin": "https://vk.com",
            "utf8": "1",
            "email": login,
            "pass": password,
            "lg_h": search_re(RE_LOGIN_HASH, response.text)
        }
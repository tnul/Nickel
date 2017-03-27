import json, httpclient, tables, re, os, strutils, htmlparser, xmltree, streams, cookies


const LoginUrl = "https://m.vk.com"
const AuthorizeUrl = "https://oauth.vk.com/authorize"

let file = open("/home/tiber/NimProjects/VKBot/src/logindata", fmRead)
var 
  login, password: string
  line: string

while file.readLine(line):
  let data = line.split(":")
  login = data[0]
  password = data[1]
let formRe = re"""<form(?= ).* action="(.+)""""
proc getFormAction(text: string): string =
  let data = text.findAll(formRe)
  if len(data) > 0:
    let splitted =  data[0].split("action=")[1]
    return splitted[1..^2]

let authSession = newHttpClient()
let pageResp = authSession.request(LoginUrl, httpMethod = HttpGet)
#for k, v in pairs(pageResp.headers):
#  echo k, " = ", v
let formAction = getFormAction(pageResp.body)
authSession.headers = newHttpHeaders({ "Content-Type": "application/x-www-form-urlencoded" })
let authResp = authSession.request(formAction, httpMethod = HttpPost, body = $ %*{"email": login, "pass": password})
#for k, v in pairs(authResp.headers):
#  echo k, " = ", v
#echo authResp.headers["location"]
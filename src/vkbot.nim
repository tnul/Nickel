# StdLib modules
import json  # for json processing
import httpclient  # HttpClient type
import strutils  # parsing strings, strings.contains
import tables  # dict-like, for conversion from json
import times  # to output time
import os # os operations

# Nimble modules
import strfmt  # interp

# Own and 3-rd party one-file modules
import utils/unpack, utils/lexim/lexim  # unpack macro and case: with regexp macro
import types
import vkapi


import plugins/ [example, greeting, curtime]

proc getLongPollUrl(data: LongPollData): string =
  ## Get URL for Long Polling server based on LongPollData info
  let url = interp"https://${data.server}?act=a_check&key=${data.key}&ts=${data.ts}&wait=25&mode=2&version=1"
  return url

proc processCommand(body: string): Command =
  ## Process string {body} and return Command object
  let values = body.split()
  return Command(command: values[0], arguments: values[1..values.high()])
  
proc processMessage(bot:VkBot, msg: Message): bool =
  ## Process message: mark it as read if needed, pass it to plugins etc...
  let cmdObj = msg.cmd
  case cmdObj.command:
    of "привет":
      greeting.call(bot.api, msg)
    of "время":
      curtime.call(bot.api, msg)
    of "тест":
      example.call(bot.api, msg)
    else:
      discard

proc processLpMessage(bot:VkBot, event: seq[JsonNode]) =
  ## Process raw message event from Long Polling
  # Extract values from new message event
  event.extract(msgId, flags, peerId, ts, subject, text, attaches)

  # Cast integer number to set of enum values
  let msgFlags: set[Flags] = cast[set[Flags]](int(flags.getNum()))

  # If we've sent this message - we don't need to process it
  if Flags.Outbox in msgFlags:
    return
  
  # Create Command instance
  let cmd = processCommand(text.str.replace("<br>", "\n"))
  # Create a MessageUpdate instance 
  let message = Message(
    msgId: int(msgId.getNum()),
    peerId: int(peerId.getNum()),
    timestamp: int(ts.getNum()),
    cmd: cmd,
    attachments: attaches
  )
  discard bot.processMessage(message)

proc newBot(token: string): VkBot =
  let api = newAPI(token)
  var lpData = LongPollData(key: "", server: "", ts: 1)
  return VkBot(
    api: api, 
    lpData: lpData, 
    lpURL: "", 
    running: false
  )


proc mainLoop(bot: var VkBot)

proc startBot(bot: var VkBot) = 
  ## Get Long Polling server that we need to connect to
  let data = bot.api.callMethod("messages.getLongPollServer")
  
  bot.lpData = LongPollData(
    key: data["key"].str, 
    server: data["server"].str, 
    ts: int(data["ts"].getNum())
  )
  ## Set appropriate URL for Long Polling
  bot.lpUrl = getLongPollUrl(bot.lpData)
  bot.running = true
  bot.mainLoop()

proc mainLoop(bot: var VkBot) =
  ## Main bot loop (events are listened here)
  while bot.running:
    # Parse response body to JSON
    let resp = parseJson(bot.api.http.get(bot.lpUrl).body)
    # Update our timestamp with new one
    bot.lpData.ts = int(resp["ts"].getNum())
    let updates = resp["updates"]
    for event in updates:
      let elems = event.getElems()
      let eventType = elems[0]
      let eventData = elems[1..elems.high()]
      case event[0].getNum():
        # Event type 4 - we've got new message
        of 4:
          bot.processLpMessage(eventData)
        else:
          discard
    # We need to update our url with new timestamp, so let's do it
    bot.lpUrl = getLongPollUrl(bot.lpData)


proc gracefulShutdown() {.noconv.} =
    ## Gracefully disable bot
    echo("Shutting down the bot...")
    sleep(500)
    quit(0)

when isMainModule:
  echo("Reading access_token from .TOKEN file...")
  let token = readLine(open(".TOKEN", fmRead))
  var bot = newBot(token)
  # Set our hook to Control+C - will be useful in future
  # (close database, end queries etc...)
  setControlCHook(gracefulShutdown)
  echo("Starting the main bot loop...")
  bot.startBot()
  
import json, httpclient

# We export all types and fileds from there to other modules
type
  LongPollData* = object
    key*: string
    server*: string
    ts*: int

  Flags* {.pure.} = enum 
    Unread, Outbox, Replied, 
    Important, Chat, Friends, 
    Spam, Deleted, Fixed, Media
  
  Command* = object
    command*: string
    arguments*: seq[string]

  Message* = object
    msgId*: int
    peerId*: int
    timestamp*: int
    cmd*: Command
    attachments*: JsonNode
  
  VkApi* = object
    token*: string
    http*: HttpClient
    
  VkBot* = object
    api*: VkApi
    lpData*: LongPollData
    lpURL*: string
    running*: bool





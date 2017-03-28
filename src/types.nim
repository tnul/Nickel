import json, httpclient, queues

# We export all types and fileds from there to other modules
type
  LongPollData* = object
    key*: string
    server*: string
    ts*: int64

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
    subject*: string
    cmd*: Command
    attachments*: JsonNode
  
  VkApi* = ref object
    token*: string
    http*: AsyncHttpClient
    reqCount*: byte

  
  VkBot* = ref object
    api*: VkApi
    lpData*: LongPollData
    lpURL*: string
    running*: bool

  KeyVal* = seq[tuple[key: string, val: string]]





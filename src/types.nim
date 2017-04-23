import json, httpclient, queues, asyncdispatch

# Все эти типы и поля доступны в других методах.
# Экспортируемые типы и поля указываются знаком *

type
  LongPollData* = object
    key*: string  # Ключ сервера 
    server*: string  # URL сервера
    ts*: int64  # Последняя метка времени
  
  Attachment* = tuple[kind, oid, id, token, link: string]

  Flags* {.pure.} = enum  # Флаги события нового сообщения Long Polling
    Unread, Outbox, Replied, 
    Important, Chat, Friends, 
    Spam, Deleted, Fixed, Media
  
  Command* = object
    name*: string  # Сама команда
    args*: seq[string]  # Последовательность аргументов

  Message* = object
    id*: int  # ID сообщения
    pid*: int  # ID отправителя
    timestamp*: int  # Дата отправки
    subject*: string  # Тема 
    cmd*: Command  # Объект команды для данного сообщения
    body*: string
    doneAttaches*: seq[Attachment]  # Приложения к сообщению
  
  BotConfig* = object
    token*: string
    logMessages*: bool
    logCommands*: bool
    errorMessage*: string
    reportErrors*: bool
    logErrors*: bool
    fullReport*: bool
  
  VkApi* = ref object
    token*: string  # Токен VK API
    reqCount*: byte

  
  VkBot* = ref object
    api*: VkApi  # Объект VK API
    lpData*: LongPollData  # Информация о сервере Long Pooling
    lpURL*: string  # URL сервера Long Pooling
    config*: BotConfig

  ModuleFunction* = proc(api: VkApi, msg: Message): Future[void]

  Module* = object
    name*: string
    usages*: seq[string]



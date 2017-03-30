import json, httpclient, queues

# Все эти типы и поля доступны в других методах.
# Экспортируемые типы и поля указываются знаком *

type
  LongPollData* = object
    key*: string  # Ключ сервера 
    server*: string  # URL сервера
    ts*: int64  # Последняя метка времени

  Flags* {.pure.} = enum  # Флаги события нового сообщения Long Polling
    Unread, Outbox, Replied, 
    Important, Chat, Friends, 
    Spam, Deleted, Fixed, Media
  
  Command* = object
    command*: string  # Сама команда в виде строки
    arguments*: seq[string]  # Последовательность аргументов

  Message* = object
    msgId*: int  # ID сообщения
    peerId*: int  # ID отправителя
    timestamp*: int  # Дата отправки
    subject*: string  # Тема 
    cmd*: Command  # Объект команды для данного сообщения
    body*: string
    attachments*: JsonNode  # Приложения к сообщению
  
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
    http*: AsyncHttpClient  # Объект HTTP клиента
    reqCount*: byte

  
  VkBot* = ref object
    api*: VkApi  # Объект VK API
    lpData*: LongPollData  # Информация о сервере Long Pooling
    lpURL*: string  # URL сервера Long Pooling
    running*: bool  # Работает ли бот
    config*: BotConfig





import json, httpclient, queues

# Все эти типы и поля доступны в других методах (знак *)
type
  LongPollData* = object
    key*: string  # Ключ сервера 
    server*: string  # URL сервера
    ts*: int64  # Последняя метка времени

  Flags* {.pure.} = enum  # Флаги сообщения в лонг пуллинге
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
    attachments*: JsonNode  # Приложения к сообщению
  
  VkApi* = ref object
    token*: string  # Токен VK API
    http*: AsyncHttpClient  # Объект HTTP клиента
    reqCount*: byte

  
  VkBot* = ref object
    api*: VkApi  # Объект VK API
    lpData*: LongPollData  # Информация о сервере Long Pooling
    lpURL*: string  # URL сервера Long Pooling
    running*: bool  # Работает ли бот

  KeyVal* = seq[tuple[key: string, val: string]]





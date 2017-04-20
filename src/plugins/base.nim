# Очень рекомендуется include'ить этот файл во все плагины
{.experimental.}
import ../types
import ../vkapi
import ../command
import ../utils
import json  # Для парсинга JSON
import strutils  # Строковые операции
import asyncdispatch  # Асинхронность
import strtabs  # Для работы с StringTable
import random  # Для функций рандома
import strfmt  # Для строкой интерполяции - interp
import tables  # Для некоторых манипуляций во время компиляции
import meta  # упрощение создания плагинов
# Рандомизируем вывод рандома (иначе он будет всегда одинаков в каждом запуске)
randomize()  

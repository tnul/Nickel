# Очень рекомендуется include'ить этот файл во все плагины
{.experimental.}
import ../types  # типы данных
import ../vkapi  # VK API
import ../command  # процедура handle
import ../utils  # утилиты
import ../meta  # метапрограммирование
import json  # Парсинг JSON
import strutils  # Строковые операции
import asyncdispatch  # Асинхронность
import strtabs  # Для работы с StringTable
import random  # Для функций рандома
import strfmt  # Для строкой интерполяции - interp
import tables  # Для некоторых манипуляций во время компиляции
# Рандомизируем вывод рандома (иначе он будет всегда одинаков в каждом запуске)
randomize()
# Очень рекомендуется include'ить этот файл во все плагины
{.experimental.}
import ../types  # типы данных
import ../vkapi  # VK API
import ../command  # Процедура handle
import ../utils  # Утилиты
import ../meta  # Метапрограммирование
import json  # Парсинг JSON
import strutils  # Строковые операции
import asyncdispatch  # Асинхронность
import strtabs  # Работа с StringTable
import random  # Функции рандома
import tables  # Обработка модулей во время компиляции
import logging  # Логгирование
# Рандомизируем вывод рандома (иначе он будет всегда одинаков в каждом запуске)
randomize()
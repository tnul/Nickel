# Очень рекомендуется include'ить этот файл во все плагины
{.experimental.}
import ../types
import ../vkapi
import ../utils
import json  # Для парсинга JSON
import strutils  # Строковые операции
import threadpool
import strtabs  # Для работы с StringTable
import random  # Для функций рандома
import strfmt  # Для строкой интерполяции - interp
# Рандомизируем вывод рандома (иначе он будет всегда одинаков в каждом запуске)
randomize()  

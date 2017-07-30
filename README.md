Nickel (Никель) [![Build Status](https://travis-ci.org/TiberiumN/Nickel.svg?branch=master)](https://travis-ci.org/TiberiumN/Nickel)
======

Чат-бот для ВКонтакте, написанный на языке Nim.

## Текущий статус проекта
Этот бот может работать как и от имени пользователя (авторизация от имени приложения ВКонтакте на iPhone), так и от группы (через Long Polling или Callback API)

## Модули (доступные помечены галочкой)
- [x] Приветствие (Приветствует пользователя) - `привет`
- [x] Случайные мемы - `мемы`
- [x] Случайные мемы с 2ch - `двач`
- [x] Случайные загадки - `загадка`
- [x] Случайные факты - `факт`
- [x] Функции случайных чисел (случайные числа, оценки, шар предсказаний, случайная дата)
- [x] Курс валют (Отображение курсов основных валют) - `курс`
- [x] Время (Показывает текущую дату и время) - `время`
- [x] Блокнот (Может запоминать и вспоминать строки) - `напомни` и `запомни`
- [x] Рассказать шутку (берёт случайную цитату с https://bash.im) - `пошути`
- [x] Выключение (Выключает бота, если команду послал администратор бота) - `выключись`
- [x] Калькулятор - `посчитай 1+1`
- [x] Операции с текстом (перевернуть текст, зачеркнуть текст, сгенерировать смех)
- [x] Получение погоды - `погода в Москве завтра`
- [x] Получение краткого описания (первого абзаца) с Википедии
- [x] Хелперы (сокращение ссылки, ID пользователя по пересланному сообщению)
- [x] Перевод текста через API Яндекс.Переводчика - `переведи на китайский Привет!`
- [ ] Автообновление статуса
- [ ] Пересылка сообщений другому пользователю
- [ ] Озвучивание текста через голосовые сообщения

В данном списке могут отстутствовать какие-либо модули и команды, которые есть в боте.
Просмотрите файлы в папке src/modules для более точной информации

## Возможности (доступные и запланированные)
- [x] Полная асинхронность
- [x] Работа от имени группы
- [x] Работа от имени группы через Callback API
- [x] Конфигурация
- [x] Обработка ошибок
- [x] Логгирование событий в консоль
- [x] Возможность задать несколько команд для одного модуля
- [x] Система модулей
- [x] Упрощённое создание модулей с помощью метапрограммирования (DSL)
- [x] Автоматическое распознавание неправильной раскладки
- [x] Работа от имени пользователя (через авторизацию под именем Android приложения ВК)
- [x] Возможность создавать и изменять префиксы бота
- [x] Автоматическое использование execute для ускорения работы бота под высокой нагрузкой
- [ ] Конфигурация модулей и возможность изменения команд
- [ ] Хранилище данных
- [ ] Тестирование производительности и оптимизация (если необходимо)

## Создание модулей
В папке `src/modules` есть пример модуля в файле example.nim, который отвечает на команду `тест`
Там есть и другие модули, код которых можно изучить для понимания того, что можно реализовать с помощью бота.

Модули могут работать со всеми методами API ВКонтакте (от имени группы - только те, которые можно выполнять от имени группы).

Пример простейшего модуля, который отвечает на команду пользователя "привет":
```nim
include base

module "Приветствие":
  command "привет":
    usage = "привет - поприветствовать пользователя"
    answer "Привет!"
```
#### Связь со мной
Меня можно найти в ВК - https://vk.com/tiberium_1111

Nickel (Никель) [![Присоединись к чату на https://gitter.im/NickelVK/Lobby](https://badges.gitter.im/NickelVK/Lobby.svg)](https://gitter.im/NickelVK/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Travis CI](https://travis-ci.org/VKBots/Nickel.svg?branch=master)](https://travis-ci.org/TiberiumN/Nickel) [![App Veyor](https://ci.appveyor.com/api/projects/status/futyiif4dq7blmof/branch/master?svg=true)](https://ci.appveyor.com/project/TiberiumPY/nickelvk/branch/master)
======

Чат-бот для ВКонтакте в ранней стадии разработки, написанный на языке Nim.
В данный момент не подходит для повседневного использования, однако, если вы заинтересованы в использовании бота в будущем - помогите в поиске багов и крашей (а так же предлагайте улучшения)!

## Текущий статус проекта
Этот бот может работать как и от имени пользователя (авторизация от имени Android приложения), так и от группы

## Модули (доступные помечены галочкой)
- [x] Приветствие (Приветствует пользователя) - `привет`
- [x] Случайное число с разными диапазонами - `рандом`
- [x] Случайные мемы - `мемы`
- [x] Случайные мемы с 2ch - `двач`
- [x] Случайные загадки - `загадка`
- [x] Случайные факты - `факт`
- [x] Случайная дата - `когда`
- [x] Случайная оценка от 1 до 10 - `оцени`
- [x] Курс валют (Отображение курсов основных валют) - `курс`
- [x] Шар предсказаний (Решает за вас) - `шар`
- [x] Время (Показывает текущую дату и время) - `время`
- [x] Блокнот (Может запоминать и вспоминать строки) - `напомни` и `запомни`
- [x] Рассказать шутку (берёт случайную цитату с https://bash.im) - `пошути`
- [x] Выключение (Выключает бота, если команду послал администратор бота) - `выключись`
- [x] Калькулятор - `посчитай 1+1`
- [x] Интеграция с iii.ru - `сеть привет`
- [x] Переворачивание текста (после получения ответа от бота нужно обновить страницу) - `переверни Привет!`
- [x] Генератор АЗХ - `лол 10`
- [x] Получение погоды - `погода в Москве завтра`
- [ ] Автообновление статуса
- [ ] Пересылка сообщений другому пользователю
- [ ] Озвучивание текста через голосовые сообщения
- [ ] Получение данных с Википедии

## Возможности (доступные и запланированные)
- [x] Полная асинхронность
- [x] Работа от имени группы
- [x] Конфигурация
- [x] Обработка ошибок
- [x] Логгирование событий в консоль
- [x] Возможность задать несколько команд для одного модуля
- [x] Система модулей
- [x] Упрощённое создание модулей с помощью метапрограммирования (DSL)
- [x] Автоматическое распознавание неправильной раскладки
- [x] Работа от имени пользователя (через авторизацию под именем Android приложения ВК)
- [x] Возможность создавать и изменять префиксы бота
- [ ] Конфигурация модулей и возможность изменения команд
- [ ] Хранилище данных
- [ ] Система плагинов (в виде .dll, которые могут подгружаться при старте бота)
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

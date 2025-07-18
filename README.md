# RAM_Cleaner
Проект для автоматической очистки оперативной памяти с использованием RAMMap.exe в фоновом режиме.  
(на случай если у вас в офисе никогда не перезагружаются ПК)

## Описание
Этот проект состоит из нескольких компонентов, которые работают вместе для:
1. Синхронизации необходимых файлов с сетевого диска на локальные машины
2. Скрытого выполнения очистки памяти через RAMMap
3. Логирования всех операций

## Компоненты
### Зачем нужны VBS?
- Они нужны для скрытого запуска скриптов, так, что окно консоли даже не моргает  
(при запуске скрытого режима через параметры powershell окно консоли на милисекунду показывается, а это раздражает, плюс фокус становиться на нем, и если кто то что то печатал то фокус с поля печати слетает)

### 1. `hidden_start_sync.vbs`
- **Назначение**: Запускает синхронизирующий PowerShell-скрипт

### 2. `Sync-RAMCleaner.ps1`
- **Назначение**: Синхронизирует файлы с сетевого диска на локальную машину
- **Особенности**:
  - Копирует только изменившиеся файлы (сравнивает дату модификации)
  - Создает целевую директорию при необходимости
  - Логирует ошибки синхронизации

### 3. `hidden_start_cleaner.vbs`
- **Назначение**: Запускает основной скрипт очистки памяти

### 4. `RAMCleaner.ps1`
- **Назначение**: Основной скрипт очистки памяти
- **Особенности**:
  - Использует RAMMap.exe для очистки памяти
  - Работает полностью скрыто
  - Поддерживает lock-файлы для предотвращения дублирующего запуска
  - Логирует результаты очистки
  - Выполняет ротацию логов

## Требования
1. Windows 10/11
2. PowerShell 5.1+
3. Доступ к сетевой папке
4. Права администратора для RAMCleaner.ps1

## Установка
1. Разместите все файлы в соответствующих директориях :  
\nas\Distrib\script\RAMCleaner (замените этот путь на свой внутри скриптов)  
├── RAMMap.exe  
├── Scripts\  
│ ├── RAMCleaner.ps1  
│ ├── Sync-RAMCleaner.ps1  
│ ├── hidden_start_cleaner.vbs  
│ └── hidden_start_sync.vbs  
└── debug\ (директория для ошибок копирования)  

Настройте запуск `hidden_start_sync.vbs` на клиентских машинах для синфронизации файлов и `hidden_start_cleaner.vbs` для отчистки  

## Безопасность
- RAMCleaner требует прав администратора только для выполнения операций с памятью
- Все операции логируются

## Известные ограничения
1. Очистка Modified Page List и Working Sets отключена из-за потенциальных проблем, можете рискнуть
2. Для работы требуется стабильное сетевое соединение с сетевым диском
3. Логи могут занимать до 5MB на каждой машине

# Мои GPO:
1) RAMCleaner Deployment  
Задача в планировщик заданий на пользователя
Действия:
- Триггер: один раз в день (ставьте время когда пользователи только начали работать за ПК, у меня это 10 утра)
- Запуск программы wscript.exe
- Аргументы: //B "\\nas\Distrib\script\RAMCleaner\Scripts\hidden_start_sync.vbs" (меняете этот путь на тот где у вас лежит скрипт)
3) RAMCleaner  
Задача в планировщик заданий на компьютер
- Запуск от имени SYSTEM с повышенными правами  
Действия:
- Триггер: один раз в день (ставьте время когда пользователи НЕ работаю за ПК, у меня это 2 ночи)
- Запуск программы wscript.exe
- Аргументы: //B "C:\Users\Public\RAMCleaner\hidden_start_cleaner.vbs" (это оставляем как есть, первый скрипт деплоит основной скрипт отчистки сюда)

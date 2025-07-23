# ram_cleaner_automation
**Назначение**: Автоматическая очистка оперативной памяти Windows через RAMMap.exe с развертыванием через Group Policy.  
**Функционал**:  
- Скрытый запуск очистки памяти (zero UI)  
- Интеграция с планировщиком заданий  
- Детальное логирование состояния памяти  
- Защита от параллельного выполнения  

### ⚙️ Настройка
Замена обязательных параметров в `RAMCleaner.ps1`:
```powershell
# Пути к компонентам
$rammapPath = "\\сервер\share\RAMCleaner\RAMMap.exe"  # Требует прав на выполнение для SYSTEM
$logDir = "\\сервер\share\RAMCleaner\logs\"          # Требует прав на запись для COMPUTER$

# Параметры работы
$lockTimeout = 600  # 10 минут (макс. время блокировки)
$maxLogSize = 5MB   # Ротация логов
```
- А так де поменять путь до скрипта в vbs файле
### 🛠 Технологии
- **PowerShell 5.1+**: Основная логика скрипта  
- **RAMMap.exe (Sysinternals)**: Низкоуровневая работа с памятью  
- **Windows Task Scheduler**: Планирование ежедневного выполнения  
- **VBScript**: Скрытый запуск (`hidden_start_cleaner.vbs`)  
- **Многоуровневое логирование**:  
  - Файловое: `\\сервер\share\RAMCleaner\logs\%COMPUTERNAME%.log`  
  - Формат записей: `[2025-07-23 02:00:15] УРОВЕНЬ: Сообщение`  

### 🚀 Запуск
#### Ручная установка (администратор):
1. Временное разрешение скриптов:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   ```
2. Запуск очистки:
   ```powershell
   \\сетевой_путь\RAMCleaner.ps1
   ```

#### Автоматизация через GPO:
1. **Разместите файлы в сетевой папке**:
   - `RAMCleaner.ps1`  
   - `hidden_start_cleaner.vbs`  
   - `RAMMap.exe`  

2. **Настройте политику (Computer Configuration)**:
   - Policies → Windows Settings → Scripts → Startup  
   - Добавьте скрипт:  
     - **Script**: `wscript.exe`  
     - **Parameters**: `//B "\\сетевой_путь\hidden_start_cleaner.vbs"`  

3. **Требования к клиентам**:
   - Доступ к сетевому ресурсу с `RAMMap.exe`  
   - PowerShell 5.1+  
   - Права на выполнение для SYSTEM  

### 📌 Ключевые функции
- **Блокировка параллельного выполнения**:
  ```powershell
  $lockFile = "$env:TEMP\ramcleaner.lock"
  if (Test-Path $lockFile) { throw "Обнаружен lock-файл: $lockFile" }
  ```
- **Диагностика памяти**:
  ```powershell
  $memBefore = (Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue
  ```
- **Автоматическая ротация логов**:
  ```powershell
  if ((Get-Item $logFile).Length -gt $maxLogSize) { Clear-Content $logFile }
  ```

### 🔒 Безопасность
- **Доступ к ресурсам**:
  - `RAMMap.exe`: только выполнение для `Domain Computers`  
  - Логи: запись для `COMPUTER$`  
- **Учетные данные**:
  - Не требуются (работа от SYSTEM)  
- **Аудит**:
  - Все операции фиксируются в логах с timestamp  

### ⚠️ Типовые проблемы
| Ошибка | Решение |
|--------|---------|
| `RAMMap not found` | Проверить доступность `\\сервер\share` для `COMPUTER$` |
| `Access denied` | Убедиться что GPO применяется от SYSTEM |
| `Lock file stuck` | Удалить вручную `%TEMP%\ramcleaner.lock` |
| `No logs created` | Проверить права на запись в `$logDir` |

### 📊 Мониторинг
1. **Логи выполнения**:
   ```
   \\сервер\share\RAMCleaner\logs\PC-NAME.log
   Пример записи:
   [2025-07-23 02:00:15] INFO: Память до очистки: 2048 MB
   [2025-07-23 02:00:45] INFO: Освобождено 512 MB (25%)
   ```

2. **Проверка работы**:
   - Убедиться что процесс `RAMMap.exe` завершается  
   - Отсутствие ошибок в логах  

> **Для отладки GPO**:  
> `gpresult /h report.html`  
> Проверить применение политики в разделе:  
> `Computer Configuration → Policies → Windows Settings → Scripts → Startup`  

Copyright © 2025 Кодельник Максим Сергеевич (ООО "Генштаб") | MIT License

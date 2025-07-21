#Requires -RunAsAdministrator
#Requires -Version 5.1

<#
.SYNOPSIS
Оптимизация памяти с помощью RAMMap
.DESCRIPTION
Упрощенная версия для ночного выполнения:
- Всегда выполняет полную очистку
- Работает полностью скрыто без UI
- Логи хранятся в сетевой папке
#>

# Конфигурация
$rammapPath = "\\nas\Distrib\script\RAMCleaner\RAMMap.exe"
$logDir = "\\nas\Distrib\script\RAMCleaner\log\"
$computerName = $env:COMPUTERNAME
$logPath = Join-Path $logDir "$computerName.log"
$lockFilePath = Join-Path $logDir "$computerName.lock"
$maxLogSizeMB = 5

# Константы
$TIMEOUT_CODE = 999
$MAX_LOCK_AGE_MINUTES = 10
$PROCESS_TIMEOUT_MS = 30000
$STABILIZATION_DELAY = 15

# Вспомогательные функции
function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File $logPath -Append -Encoding utf8
    
    # Ротация логов
    if ((Get-Item $logPath -ErrorAction SilentlyContinue).Length / 1MB -gt $maxLogSizeMB) {
        $backupLog = $logPath -replace '\.log$', '_backup.log'
        Move-Item $logPath $backupLog -Force -ErrorAction SilentlyContinue
    }
}

function Get-AvailableMemoryMB {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        [math]::Round($os.FreePhysicalMemory / 1024, 2)
    }
    catch {
        Log "ОШИБКА получения памяти: $_"
        return 0
    }
}

# Инициализация окружения
try {
    # Создаем папку для логов если нужно
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop | Out-Null
    }
}
catch {
    exit 1
}

# Проверка блокировки
if (Test-Path $lockFilePath) {
    $lockTime = (Get-Item $lockFilePath).CreationTime
    if ((New-TimeSpan -Start $lockTime -End (Get-Date)).TotalMinutes -gt $MAX_LOCK_AGE_MINUTES) {
        Remove-Item $lockFilePath -Force
        Log "Удален устаревший lock-файл"
    }
    else {
        Log "ОШИБКА: Скрипт уже выполняется"
        exit 2
    }
}
else {
    $null > $lockFilePath
}

# Главный блок выполнения
try {
    $scriptStart = Get-Date
    Log "=== НАЧАТА ОЧИСТКА ПАМЯТИ ==="

    # Проверка RAMMap
    if (-not (Test-Path $rammapPath)) {
        Log "ОШИБКА: RAMMap не найден"
        exit 1
    }

    # Диагностика памяти
    $beforeMemory = Get-AvailableMemoryMB
    Log "Память до очистки: $beforeMemory MB"

    # Функция запуска RAMMap (полностью скрытый режим)
    function Invoke-RAMMapClean {
        param(
            [string]$Operation,
            [string[]]$ArgsList
        )
        Log "RAMMap: $Operation"
        
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $rammapPath
            $psi.Arguments = $ArgsList -join " "
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $psi.CreateNoWindow = $true
            $psi.UseShellExecute = $false
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $psi
            
            $process.Start() | Out-Null
            
            # Ожидаем завершения с таймаутом
            if (-not $process.WaitForExit($PROCESS_TIMEOUT_MS)) {
                $process.Kill() | Out-Null
                Log "ТАЙМАУТ: $Operation"
                return $TIMEOUT_CODE
            }
            
            return $process.ExitCode
        }
        catch {
            Log "ОШИБКА: $Operation - $_"
            return 1
        }
    }

    # Последовательность операций очистки
    $exitCodes = @()
    
    # 1. Очистка Standby List
    $exitCodes += Invoke-RAMMapClean -Operation "Очистка Standby List" -ArgsList @("/accepteula", "-Es")
    
    # Проверка результатов
    $success = ($exitCodes | Where-Object { $_ -ne 0 } | Measure-Object).Count -eq 0
    Log "Результат: $(if ($success) {'Успех'} else {'Ошибка'}) [Коды: $($exitCodes -join ', ')]"

    # Ожидание стабилизации
    Start-Sleep -Seconds $STABILIZATION_DELAY
    
    # Послеоперационная диагностика
    $afterMemory = Get-AvailableMemoryMB
    $memoryDelta = [math]::Max(0, $afterMemory - $beforeMemory)
    
    $percentFreed = if ($beforeMemory -gt 0) { 
        [math]::Round(($memoryDelta / $beforeMemory) * 100, 2) 
    } else { 0 }
    
    Log "Память после очистки: $afterMemory MB"
    Log "Освобождено: $memoryDelta MB ($percentFreed%)"

    # Финализация
    $duration = (Get-Date) - $scriptStart
    Log "=== ЗАВЕРШЕНО ЗА $($duration.ToString('mm\:ss')) ==="
}
catch {
    $errorMsg = "КРИТИЧЕСКАЯ ОШИБКА: $($_.Exception.Message)"
    Log $errorMsg
}
finally {
    if (Test-Path $lockFilePath) {
        Remove-Item $lockFilePath -Force -ErrorAction SilentlyContinue
    }
}
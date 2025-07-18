$sourceFiles = @(
    "\\nas\Distrib\script\RAMCleaner\Scripts\RAMCleaner.ps1"
    "\\nas\Distrib\script\RAMCleaner\RAMMap.exe"
    "\\nas\Distrib\script\RAMCleaner\Scripts\hidden_start_cleaner.vbs"
)
$targetDir = "C:\Users\Public\RAMCleaner\"
$logDir = "\\nas\Distrib\script\RAMCleaner\debug\"
$logFile = Join-Path $logDir "$(Get-Date -Format 'dd-MM-yyyy').log"

# Массив для сбора ошибок
$errorMessages = @()

try {
    # Создание целевой директории
    if (-not (Test-Path -Path $targetDir)) {
        try {
            New-Item -ItemType Directory -Path $targetDir -Force -ErrorAction Stop | Out-Null
        }
        catch {
            $errorMessages += "CREATE_DIR_FAILED: $($_.Exception.Message)"
        }
    }

    foreach ($src in $sourceFiles) {
        $fileName = [System.IO.Path]::GetFileName($src)
        $dest = Join-Path -Path $targetDir -ChildPath $fileName
        
        try {
            # Проверка существования источника
            if (-not (Test-Path -Path $src)) {
                $errorMessages += "SOURCE_MISSING: $src"
                continue
            }
            
            # Проверка необходимости копирования (сравниваем дату и время с точностью до минут)
            $copyNeeded = $true
            if (Test-Path -Path $dest) {
                $srcTime = (Get-Item -LiteralPath $src).LastWriteTime.ToString("yyyyMMddHHmm")
                $destTime = (Get-Item -LiteralPath $dest).LastWriteTime.ToString("yyyyMMddHHmm")
                
                if ($srcTime -eq $destTime) {
                    $copyNeeded = $false
                }
            }
            
            # Копирование файла, если время изменения (до минут) различается
            if ($copyNeeded) {
                Copy-Item -Path $src -Destination $dest -Force -ErrorAction Stop
            }
        }
        catch {
            $errorMessages += "COPY_FAILED: $($_.Exception.Message) [$src]"
        }
    }
}
catch {
    $errorMessages += "GLOBAL_ERROR: $($_.Exception.Message)"
}
finally {
    # Запись всех ошибок одной строкой
    if ($errorMessages.Count -gt 0) {
        $logEntry = "[$(Get-Date -Format 'HH:mm')][ps][$($env:COMPUTERNAME)] $($errorMessages -join '; ')"

        try {
            # Создание директории для логов при необходимости
            if (-not (Test-Path -Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop | Out-Null
            }
            Add-Content -Path $logFile -Value $logEntry -ErrorAction Stop
        }
        catch {
            # Фатальная ошибка логирования - не предпринимаем действий
        }
    }
}
Option Explicit

' Конфигурация
Const psScriptPath = "\\nas\Distrib\script\RAMCleaner\Scripts\Sync-RAMCleaner.ps1"
Const logDir = "\\nas\Distrib\script\RAMCleaner\debug\"

Dim objShell, objFSO, computerName, timestamp, command, errorMessage
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

On Error Resume Next
computerName = objShell.ExpandEnvironmentStrings("%COMPUTERNAME%")
timestamp = Now()
errorMessage = ""

' Основная логика
If Not objFSO.FileExists(psScriptPath) Then
    errorMessage = "PS_SCRIPT_MISSING: " & psScriptPath
Else
    ' Формируем команду для скрытого выполнения PowerShell
    command = "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File """ & psScriptPath & """"
    objShell.Run command, 0, True
    
    ' Обрабатываем ошибки запуска
    If Err.Number <> 0 Then
        errorMessage = "LAUNCH_FAILED: " & Err.Description & " [0x" & Hex(Err.Number) & "]"
        Err.Clear
    End If
End If

' Логирование при наличии ошибок
If errorMessage <> "" Then
    WriteLog errorMessage
End If

Set objFSO = Nothing
Set objShell = Nothing

' Функция записи в лог
Sub WriteLog(message)
    Dim logFile, logEntry, file, folder
    
    ' Форматируем имя файла лога
    logFile = logDir & _
              Right("0" & Day(timestamp), 2) & "-" & _
              Right("0" & Month(timestamp), 2) & "-" & _
              Year(timestamp) & ".log"
    
    ' Форматируем запись лога
    logEntry = "[" & Right("0" & Hour(timestamp), 2) & ":" & _
               Right("0" & Minute(timestamp), 2) & "][vbs][" & _
               computerName & "] " & message
               
    On Error Resume Next ' Игнорируем ошибки при записи лога
    
    ' Создаем директорию логов если нужно
    folder = objFSO.GetParentFolderName(logFile)
    If Not objFSO.FolderExists(folder) Then
        objFSO.CreateFolder(folderPath)
    End If
    
    ' Записываем в лог
    Set file = objFSO.OpenTextFile(logFile, 8, True) ' 8 = ForAppending
    file.WriteLine logEntry
    file.Close
    
    On Error GoTo 0
End Sub
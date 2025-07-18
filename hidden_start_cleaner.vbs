' Скрытое выполнение PowerShell-скрипта
Set objShell = CreateObject("WScript.Shell")
strCommand = "powershell.exe -ExecutionPolicy Bypass -File ""C:\Users\Public\RAMCleaner\RAMCleaner.ps1"""
objShell.Run strCommand, 0, False
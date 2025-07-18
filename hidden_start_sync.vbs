Option Explicit

' ������������
Const psScriptPath = "\\nas\Distrib\script\RAMCleaner\Scripts\Sync-RAMCleaner.ps1"
Const logDir = "\\nas\Distrib\script\RAMCleaner\debug\"

Dim objShell, objFSO, computerName, timestamp, command, errorMessage
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

On Error Resume Next
computerName = objShell.ExpandEnvironmentStrings("%COMPUTERNAME%")
timestamp = Now()
errorMessage = ""

' �������� ������
If Not objFSO.FileExists(psScriptPath) Then
    errorMessage = "PS_SCRIPT_MISSING: " & psScriptPath
Else
    ' ��������� ������� ��� �������� ���������� PowerShell
    command = "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File """ & psScriptPath & """"
    objShell.Run command, 0, True
    
    ' ������������ ������ �������
    If Err.Number <> 0 Then
        errorMessage = "LAUNCH_FAILED: " & Err.Description & " [0x" & Hex(Err.Number) & "]"
        Err.Clear
    End If
End If

' ����������� ��� ������� ������
If errorMessage <> "" Then
    WriteLog errorMessage
End If

Set objFSO = Nothing
Set objShell = Nothing

' ������� ������ � ���
Sub WriteLog(message)
    Dim logFile, logEntry, file, folder
    
    ' ����������� ��� ����� ����
    logFile = logDir & _
              Right("0" & Day(timestamp), 2) & "-" & _
              Right("0" & Month(timestamp), 2) & "-" & _
              Year(timestamp) & ".log"
    
    ' ����������� ������ ����
    logEntry = "[" & Right("0" & Hour(timestamp), 2) & ":" & _
               Right("0" & Minute(timestamp), 2) & "][vbs][" & _
               computerName & "] " & message
               
    On Error Resume Next ' ���������� ������ ��� ������ ����
    
    ' ������� ���������� ����� ���� �����
    folder = objFSO.GetParentFolderName(logFile)
    If Not objFSO.FolderExists(folder) Then
        objFSO.CreateFolder(folderPath)
    End If
    
    ' ���������� � ���
    Set file = objFSO.OpenTextFile(logFile, 8, True) ' 8 = ForAppending
    file.WriteLine logEntry
    file.Close
    
    On Error GoTo 0
End Sub
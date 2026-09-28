' Helpers sin ventana de CMD. Incluir con ExecuteGlobal (sin Option Explicit acá).

Function PuertoEnUso(p)
  Dim wmi, conns, c, sh2, fso2, tmp, t, txt
  PuertoEnUso = False
  On Error Resume Next
  Err.Clear
  Set wmi = GetObject("winmgmts:\\.\root\StandardCimv2")
  If Err.Number = 0 Then
    Set conns = wmi.ExecQuery("SELECT LocalPort FROM MSFT_NetTCPConnection WHERE LocalPort = " & CLng(p) & " AND State = 2")
    For Each c In conns
      PuertoEnUso = True
      Exit Function
    Next
    If Err.Number = 0 Then Exit Function
  End If
  Err.Clear
  Set sh2 = CreateObject("WScript.Shell")
  Set fso2 = CreateObject("Scripting.FileSystemObject")
  tmp = sh2.ExpandEnvironmentStrings("%TEMP%") & "\stock-port-" & p & ".txt"
  sh2.Run "cmd /c netstat -ano | findstr LISTENING | findstr :" & p & " > """ & tmp & """", 0, True
  If fso2.FileExists(tmp) Then
    Set t = fso2.OpenTextFile(tmp, 1)
    If Not t.AtEndOfStream Then txt = t.ReadAll
    t.Close
    fso2.DeleteFile tmp, True
    If InStr(1, txt, "LISTENING", vbTextCompare) > 0 Then PuertoEnUso = True
  End If
  On Error GoTo 0
End Function

Sub LiberarPuerto(p)
  Dim wmi, conns, c, wmi2, procs, proc
  On Error Resume Next
  Set wmi = GetObject("winmgmts:\\.\root\StandardCimv2")
  Set wmi2 = GetObject("winmgmts:\\.\root\cimv2")
  Set conns = wmi.ExecQuery("SELECT OwningProcess FROM MSFT_NetTCPConnection WHERE LocalPort = " & CLng(p) & " AND State = 2")
  For Each c In conns
    Set procs = wmi2.ExecQuery("SELECT * FROM Win32_Process WHERE ProcessId = " & CLng(c.OwningProcess))
    For Each proc In procs
      proc.Terminate
    Next
  Next
  On Error GoTo 0
End Sub

Function ProcesoCorriendo(nombre)
  Dim wmi, procs, proc
  ProcesoCorriendo = False
  On Error Resume Next
  Set wmi = GetObject("winmgmts:\\.\root\cimv2")
  Set procs = wmi.ExecQuery("SELECT Name FROM Win32_Process WHERE Name = '" & Replace(nombre, "'", "") & "'")
  For Each proc In procs
    ProcesoCorriendo = True
    Exit Function
  Next
  On Error GoTo 0
End Function

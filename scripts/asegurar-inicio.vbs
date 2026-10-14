' Registra inicio automatico: al encender / iniciar sesion y cada 5 minutos.
' Lo llama registrar-inicio-automatico.bat y servidor-oculto.vbs.

Option Explicit
Dim fso, sh, scriptDir, vbs, xmlFile, startup, lnk, ret, logFile

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
vbs = scriptDir & "\servidor-oculto.vbs"
xmlFile = sh.ExpandEnvironmentStrings("%TEMP%") & "\sistemastock-tarea.xml"
logFile = scriptDir & "\servidor.log"

If Not fso.FileExists(vbs) Then
  Call LogLine("asegurar-inicio: no existe servidor-oculto.vbs")
  WScript.Quit 1
End If

On Error Resume Next
startup = sh.SpecialFolders("Startup")
If startup <> "" Then
  Set lnk = sh.CreateShortcut(startup & "\SistemaStock.lnk")
  lnk.TargetPath = "wscript.exe"
  lnk.Arguments = "//B """ & vbs & """ /silent"
  lnk.WorkingDirectory = scriptDir
  lnk.WindowStyle = 7
  lnk.Description = "Control de Stock (servidor y tunel al iniciar Windows)"
  lnk.Save
  Call LogLine("asegurar-inicio: acceso en Inicio de Windows")
End If
On Error GoTo 0

Call EscribirXmlTarea(xmlFile, vbs, scriptDir, False)
ret = sh.Run("schtasks.exe /Create /TN ""SistemaStock"" /XML """ & xmlFile & """ /F", 0, True)
If ret = 0 Then
  Call LogLine("asegurar-inicio: tarea SistemaStock OK")
Else
  Call LogLine("asegurar-inicio: schtasks XML codigo=" & ret & " (reintento ONLOGON)")
  ret = sh.Run("schtasks.exe /Create /TN ""SistemaStock"" /TR ""wscript.exe //B \""" & vbs & "\"" /silent"" /SC ONLOGON /DELAY 0000:45 /F", 0, True)
  Call LogLine("asegurar-inicio: schtasks ONLOGON codigo=" & ret)
End If

Call EscribirXmlTarea(xmlFile, vbs, scriptDir, True)
ret = sh.Run("schtasks.exe /Create /TN ""SistemaStockBoot"" /XML """ & xmlFile & """ /F", 0, True)
If ret = 0 Then
  Call LogLine("asegurar-inicio: tarea SistemaStockBoot (SYSTEM) OK")
Else
  Call LogLine("asegurar-inicio: SistemaStockBoot codigo=" & ret & " (hace falta ejecutar como administrador)")
End If

On Error Resume Next
If fso.FileExists(xmlFile) Then fso.DeleteFile xmlFile, True
On Error GoTo 0

WScript.Quit 0

Sub EscribirXmlTarea(path, scriptVbs, workDir, comoSystem)
  Dim ts, cmd, args, wd
  cmd = XmlEsc("wscript.exe")
  args = XmlEsc("//B """ & scriptVbs & """ /silent")
  wd = XmlEsc(workDir)
  Set ts = fso.CreateTextFile(path, True, True)
  ts.WriteLine "<?xml version=""1.0"" encoding=""UTF-16""?>"
  ts.WriteLine "<Task version=""1.2"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">"
  ts.WriteLine "  <RegistrationInfo><Description>Control de Stock: servidor y ngrok al encender la PC</Description></RegistrationInfo>"
  ts.WriteLine "  <Triggers>"
  If comoSystem Then
    ts.WriteLine "    <BootTrigger><Enabled>true</Enabled><Delay>PT90S</Delay></BootTrigger>"
  Else
    ts.WriteLine "    <BootTrigger><Enabled>true</Enabled><Delay>PT90S</Delay></BootTrigger>"
    ts.WriteLine "    <LogonTrigger><Enabled>true</Enabled><Delay>PT45S</Delay></LogonTrigger>"
    ts.WriteLine "    <CalendarTrigger>"
    ts.WriteLine "      <Repetition><Interval>PT5M</Interval><Duration>P1D</Duration><StopAtDurationEnd>false</StopAtDurationEnd></Repetition>"
    ts.WriteLine "      <StartBoundary>2020-01-01T00:00:00</StartBoundary>"
    ts.WriteLine "      <Enabled>true</Enabled>"
    ts.WriteLine "      <ScheduleByDay><DaysInterval>1</DaysInterval></ScheduleByDay>"
    ts.WriteLine "    </CalendarTrigger>"
  End If
  ts.WriteLine "  </Triggers>"
  If comoSystem Then
    ts.WriteLine "  <Principals><Principal id=""Author""><UserId>S-1-5-18</UserId><RunLevel>HighestAvailable</RunLevel></Principal></Principals>"
  Else
    ts.WriteLine "  <Principals><Principal id=""Author""><LogonType>InteractiveToken</LogonType><RunLevel>LeastPrivilege</RunLevel></Principal></Principals>"
  End If
  ts.WriteLine "  <Settings>"
  ts.WriteLine "    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>"
  ts.WriteLine "    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>"
  ts.WriteLine "    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>"
  ts.WriteLine "    <AllowHardTerminate>true</AllowHardTerminate>"
  ts.WriteLine "    <StartWhenAvailable>true</StartWhenAvailable>"
  ts.WriteLine "    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>"
  ts.WriteLine "    <IdleSettings><StopOnIdleEnd>false</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleSettings>"
  ts.WriteLine "    <AllowStartOnDemand>true</AllowStartOnDemand>"
  ts.WriteLine "    <Enabled>true</Enabled>"
  ts.WriteLine "    <Hidden>true</Hidden>"
  ts.WriteLine "    <RunOnlyIfIdle>false</RunOnlyIfIdle>"
  ts.WriteLine "    <WakeToRun>false</WakeToRun>"
  ts.WriteLine "    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>"
  ts.WriteLine "    <Priority>7</Priority>"
  ts.WriteLine "  </Settings>"
  ts.WriteLine "  <Actions Context=""Author""><Exec>"
  ts.WriteLine "    <Command>" & cmd & "</Command>"
  ts.WriteLine "    <Arguments>" & args & "</Arguments>"
  ts.WriteLine "    <WorkingDirectory>" & wd & "</WorkingDirectory>"
  ts.WriteLine "  </Exec></Actions>"
  ts.WriteLine "</Task>"
  ts.Close
End Sub

Function XmlEsc(s)
  XmlEsc = Replace(Replace(Replace(Replace(Replace(s, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), """", "&quot;"), "'", "&apos;")
End Function

Sub LogLine(msg)
  Dim t
  On Error Resume Next
  Set t = fso.OpenTextFile(logFile, 8, True)
  t.WriteLine Now & " " & msg
  t.Close
  On Error GoTo 0
End Sub

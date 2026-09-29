' Arranca el tunel fijo de ngrok en segundo plano (sin ventana).
' Lo llama abrir-sistema.vbs y servidor-oculto.vbs cuando el servidor ya esta en 3001.

Option Explicit
Dim fso, sh, scriptDir, exe, binDir, logFile, urlFile, cfgFile, zipFile
Dim token, dominio, url, cmd

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
binDir = scriptDir & "\bin"
exe = binDir & "\ngrok.exe"
logFile = scriptDir & "\tunel.log"
urlFile = scriptDir & "\tunel-url.txt"
cfgFile = scriptDir & "\tunel-config.txt"
zipFile = binDir & "\ngrok.zip"
ExecuteGlobal fso.OpenTextFile(scriptDir & "\_util-proceso.vbs", 1).ReadAll

Call LeerConfig(cfgFile, token, dominio)

If Trim(token) = "" Or Trim(dominio) = "" Then
  Call LogLine("Falta tunel-config.txt (token o dominio). Ejecuta scripts\configurar-tunel.bat")
  WScript.Quit 0
End If

dominio = LCase(Trim(dominio))
dominio = Replace(dominio, "https://", "")
dominio = Replace(dominio, "http://", "")
dominio = Replace(dominio, "/", "")
url = "https://" & dominio

If ProcesoCorriendo("ngrok.exe") Then
  Call GuardarUrl(urlFile, url)
  Call LogLine("OK: ngrok ya estaba corriendo " & url)
  WScript.Quit 0
End If

If Not fso.FolderExists(binDir) Then fso.CreateFolder binDir

If Not fso.FileExists(exe) Then
  Call LogLine("Descargando ngrok...")
  If Not DescargarNgrok(zipFile, exe) Then
    Call LogLine("ERROR: no se pudo descargar ngrok")
    WScript.Quit 1
  End If
End If

If Not fso.FileExists(exe) Then
  Call LogLine("ERROR: falta ngrok.exe")
  WScript.Quit 1
End If

Call GuardarUrl(urlFile, url)
Call LogLine("Iniciando ngrok " & url)

' Mismo arranque de siempre (tunel-fondo.bat), pero sin ventana.
Call ArrancarOculto("cmd.exe /c call """ & scriptDir & "\tunel-fondo.bat""", scriptDir)

WScript.Quit 0

Sub LeerConfig(path, ByRef tok, ByRef dom)
  Dim t, line, eq, k, v
  tok = ""
  dom = ""
  On Error Resume Next
  If Not fso.FileExists(path) Then Exit Sub
  Set t = fso.OpenTextFile(path, 1)
  Do While Not t.AtEndOfStream
    line = Trim(t.ReadLine)
    If Left(line, 3) = Chr(239) & Chr(187) & Chr(191) Then line = Mid(line, 4)
    If Left(line, 1) = ChrW(&HFEFF) Then line = Mid(line, 2)
    line = Trim(line)
    If line <> "" And Left(line, 1) <> "#" Then
      eq = InStr(line, "=")
      If eq > 0 Then
        k = UCase(Trim(Left(line, eq - 1)))
        v = Trim(Mid(line, eq + 1))
        If k = "NGROK_AUTHTOKEN" Then tok = v
        If k = "NGROK_DOMAIN" Then dom = v
      End If
    End If
  Loop
  t.Close
  On Error GoTo 0
End Sub

Function DescargarNgrok(zipPath, exePath)
  Dim cmdDl, folder
  DescargarNgrok = False
  folder = fso.GetParentFolderName(exePath)
  cmdDl = "powershell -NoProfile -Command ""try { " & _
        "Invoke-WebRequest -Uri 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip' -OutFile '" & zipPath & "' -UseBasicParsing; " & _
        "Expand-Archive -Path '" & zipPath & "' -DestinationPath '" & folder & "' -Force; " & _
        "exit 0 } catch { exit 1 }"""
  If sh.Run(cmdDl, 0, True) = 0 And fso.FileExists(exePath) Then DescargarNgrok = True
End Function

Sub LogLine(msg)
  Dim t
  On Error Resume Next
  Set t = fso.OpenTextFile(logFile, 8, True)
  t.WriteLine Now & " " & msg
  t.Close
  On Error GoTo 0
End Sub

Sub GuardarUrl(path, value)
  Dim t
  On Error Resume Next
  Set t = fso.CreateTextFile(path, True)
  t.WriteLine value
  t.Close
  On Error GoTo 0
End Sub

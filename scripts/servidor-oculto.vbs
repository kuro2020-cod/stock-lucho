' Arranca el servidor de stock en segundo plano (sin ventana negra).
' Escribe siempre en scripts\servidor.log para poder diagnosticar.

Option Explicit
Dim fso, sh, scriptDir, proyecto, backend, logFile, envFile, batFile, ts, puerto
Dim compileBat, compileCode, nodeExe, silencioso, i

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
proyecto = fso.GetParentFolderName(scriptDir)
backend = proyecto & "\backend"
logFile = scriptDir & "\servidor.log"
envFile = backend & "\.env"
batFile = scriptDir & "\_arrancar-tmp.bat"
puerto = 3001
silencioso = False
For i = 0 To WScript.Arguments.Count - 1
  If LCase(Trim(WScript.Arguments(i))) = "/silent" Then silencioso = True
Next
ExecuteGlobal fso.OpenTextFile(scriptDir & "\_util-proceso.vbs", 1).ReadAll

Call LogLine("---- " & Now & " servidor-oculto.vbs silent=" & silencioso & " ----")
Call LogLine("Proyecto: " & proyecto)

If fso.FileExists(scriptDir & "\asegurar-inicio.vbs") Then
  sh.Run "wscript.exe //B """ & scriptDir & "\asegurar-inicio.vbs""", 0, False
End If

If Not fso.FolderExists(backend) Then
  Call Aviso("No se encontro la carpeta backend:" & vbCrLf & backend)
  WScript.Quit 1
End If

If Not fso.FileExists(envFile) Then
  Call Aviso("Falta el archivo backend\.env" & vbCrLf & "Copialo desde .env.example y pone la clave de PostgreSQL.")
  WScript.Quit 1
End If

If Not fso.FileExists(proyecto & "\frontend\dist\index.html") Then
  compileBat = scriptDir & "\_compilar-frontend-si-hace-falta.bat"
  If fso.FileExists(compileBat) Then
    Call LogLine("Compilando frontend (falta dist)...")
    compileCode = sh.Run("cmd /c """ & compileBat & """ >> """ & logFile & """ 2>&1", 0, True)
    Call LogLine("Compilacion frontend codigo=" & compileCode)
  End If
End If

If Not fso.FileExists(proyecto & "\frontend\dist\index.html") Then
  Call Aviso("Falta compilar el frontend." & vbCrLf & "Ejecuta: scripts\actualizar-sistema.bat")
  WScript.Quit 1
End If

nodeExe = FindNode()
If nodeExe = "" Then
  Call Aviso("Node.js no esta instalado o no esta en el PATH." & vbCrLf & "Instalalo desde https://nodejs.org (LTS).")
  WScript.Quit 1
End If
Call LogLine("Node: " & nodeExe)

If PuertoEnUso(puerto) And ProcesoCorriendo("ngrok.exe") Then
  Call LogLine("OK: servidor y ngrok ya estaban en marcha")
  WScript.Quit 0
End If

If Not PuertoEnUso(puerto) Then
  Call LogLine("Esperando PostgreSQL / red (inicio de Windows)...")
  WScript.Sleep 15000
End If

For i = 1 To 12
  If PuertoEnUso(puerto) Then
    Call LogLine("OK: servidor escuchando en " & puerto)
    Exit For
  End If
  Call ArrancarServidor(nodeExe)
  WScript.Sleep 10000
Next

If PuertoEnUso(puerto) Then
  For i = 1 To 8
    If ProcesoCorriendo("ngrok.exe") Then
      Call LogLine("OK: ngrok en marcha")
      Exit For
    End If
    Call ArrancarTunel()
    WScript.Sleep 8000
    If ProcesoCorriendo("ngrok.exe") Then
      Call LogLine("OK: ngrok en marcha")
      Exit For
    End If
    Call LogLine("AVISO: ngrok no aparecio, reintento " & i)
  Next
Else
  Call LogLine("AVISO: el puerto " & puerto & " sigue libre. Mira los errores en este mismo archivo (servidor.log).")
End If

WScript.Quit 0

Sub ArrancarServidor(exeNode)
  On Error Resume Next
  Set ts = fso.CreateTextFile(batFile, True)
  ts.WriteLine "@echo off"
  ts.WriteLine "cd /d """ & backend & """"
  ts.WriteLine "set NODE_ENV=production"
  ts.WriteLine """" & exeNode & """ server.js >> """ & logFile & """ 2>&1"
  ts.Close
  On Error GoTo 0
  Call LogLine("Ejecutando bat temporal: " & batFile)
  sh.Run """" & batFile & """", 0, False
End Sub

Sub Aviso(msg)
  Call LogLine("ERROR: " & Replace(msg, vbCrLf, " / "))
  If Not silencioso Then MsgBox msg, vbExclamation, "Sistema de Stock"
End Sub

Sub LogLine(msg)
  Dim t
  On Error Resume Next
  Set t = fso.OpenTextFile(logFile, 8, True)
  t.WriteLine msg
  t.Close
  On Error GoTo 0
End Sub

Function FindNode()
  Dim p, parts, i2, candidate
  FindNode = ""
  On Error Resume Next
  p = sh.ExpandEnvironmentStrings("%PATH%")
  parts = Split(p, ";")
  For i2 = LBound(parts) To UBound(parts)
    candidate = Trim(parts(i2))
    If candidate <> "" Then
      If Right(candidate, 1) <> "\" Then candidate = candidate & "\"
      If fso.FileExists(candidate & "node.exe") Then
        FindNode = candidate & "node.exe"
        Exit Function
      End If
    End If
  Next
  candidate = sh.ExpandEnvironmentStrings("%ProgramFiles%\nodejs\node.exe")
  If fso.FileExists(candidate) Then FindNode = candidate : Exit Function
  candidate = sh.ExpandEnvironmentStrings("%ProgramFiles(x86)%\nodejs\node.exe")
  If fso.FileExists(candidate) Then FindNode = candidate : Exit Function
  candidate = sh.ExpandEnvironmentStrings("%LocalAppData%\Programs\nodejs\node.exe")
  If fso.FileExists(candidate) Then FindNode = candidate : Exit Function
  On Error GoTo 0
End Function

Sub ArrancarTunel()
  Dim tunel
  tunel = scriptDir & "\tunel-oculto.vbs"
  If Not fso.FileExists(tunel) Then
    Call LogLine("AVISO: no existe tunel-oculto.vbs")
    Exit Sub
  End If
  Call LogLine("Arrancando tunel ngrok...")
  sh.Run "wscript.exe //B """ & tunel & """", 0, False
End Sub

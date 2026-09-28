' Compatibilidad con instalaciones viejas de KURO.
' Windows a veces deja una tarea o acceso directo que llama este archivo.
' Si el servidor ya corre, no hace nada y no abre ventanas.

Option Explicit
Dim fso, sh, scriptDir
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
If Not fso.FileExists(scriptDir & "\_util-proceso.vbs") Then WScript.Quit 0
ExecuteGlobal fso.OpenTextFile(scriptDir & "\_util-proceso.vbs", 1).ReadAll

If PuertoEnUso(3001) Then WScript.Quit 0

If fso.FileExists(scriptDir & "\servidor-oculto.vbs") Then
  sh.Run "wscript.exe """ & scriptDir & "\servidor-oculto.vbs""", 0, False
End If

WScript.Quit 0

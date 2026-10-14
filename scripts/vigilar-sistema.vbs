' Compatibilidad con instalaciones viejas de KURO y vigilancia periodica.
' Asegura servidor + tunel ngrok, sin ventanas.

Option Explicit
Dim fso, sh, scriptDir
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
If fso.FileExists(scriptDir & "\servidor-oculto.vbs") Then
  sh.Run "wscript.exe //B """ & scriptDir & "\servidor-oculto.vbs"" /silent", 0, False
End If

WScript.Quit 0

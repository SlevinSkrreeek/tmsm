; 
; Copyright (C) 2012 Matteo Battolla
; 
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
;

#include <File.au3>
#include <Array.au3>
#include <_XMLDomWrapper.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

$Form1 = GUICreate("TextMod Save Manager", 615, 438, 192, 124)
$Button1 = GUICtrlCreateButton("Select TexMod", 72, 80, 83, 25)
$Button2 = GUICtrlCreateButton("Select Game", 72, 112, 83, 25)
$Button3 = GUICtrlCreateButton("Add Mod", 72, 144, 81, 25)
$Button4 = GUICtrlCreateButton("Exit", 72, 240, 81, 25)
$Button5 = GUICtrlCreateButton("About", 72, 272, 81, 25)
$Label1 = GUICtrlCreateLabel("Label1", 168, 80, 436, 17)
$Label2 = GUICtrlCreateLabel("Label2", 168, 112, 436, 17)
$Button6 = GUICtrlCreateButton("Play Game", 72, 176, 83, 25)
$Button7 = GUICtrlCreateButton("Reset Mods", 72, 208, 83, 25)
$List1 = GUICtrlCreateList("", 168, 144, 441, 279)
GUISetState(@SW_SHOW)

;
; Var iniziali
;
$filename = "config.xml"
Global $path_texmod = ""
Global $path_game = ""

Local $szDrive, $szDir, $szFName, $szExt
Local $szDrive1, $szDir1, $szFName1, $szExt1
Local $szDrive2, $szDir2, $szFName2, $szExt2

Local $aLocalPath = _PathSplit(@ScriptFullPath, $szDrive, $szDir, $szFName, $szExt)

Local $ConfigPath = $szDrive & $szDir & $filename

;
;
; Gestione XML
;
;
$oOXml = ""
$oOXml = _XMLFileOpen($ConfigPath)
if @error then
	_XMLCreateFile($ConfigPath,"TexModLauncher")
	$oOXml = _XMLFileOpen($ConfigPath)
	if @error then
		Exit
	Endif
	
	setupconfig()
	
EndIf

dim $aAttName[1],$aAttVal[1] , $aAttName2[1],$aAttVal2[1]

$ret = _XMLGetAllAttrib("/TexModLauncher/Texmod",$aAttName,$aAttVal,"[1]")
$path_texmod = $aAttVal[0]

local $gameCount = _XMLGetNodeCount("/TexModLauncher/Games/Game")
$ret2 = _XMLGetAllAttrib("/TexModLauncher/Games/Game",$aAttName2,$aAttVal2,"[1]")
$path_game = $aAttVal2[1]

GUICtrlSetData ($Label1, $path_texmod)
GUICtrlSetData ($Label2, $path_game)

;;;
;; Stampa la lista dei mod nell'xml
;;;
stampamod()

;;;
;; Disegna la GUI
;;;
While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		
		Case $GUI_EVENT_CLOSE
			Exit

		Case $Button1
			$path_texmod = selecttexmod()
			_XMLSetAttrib ( "/TexModLauncher/Texmod", "Path", $path_texmod)
			GUICtrlSetData ($Label1, $path_texmod)
			
		Case $Button2
			$path_game = selectgame()
			_XMLSetAttrib ( "/TexModLauncher/Games/Game", "Path", $path_game)
			GUICtrlSetData ($Label2, $path_game)
			Local $aFilepathGame = _PathSplit($path_game, $szDrive1, $szDir1, $szFName1, $szExt1)
			_XMLSetAttrib ( "/TexModLauncher/Games/Game", "Name", $szFName1)
			
			
		Case $Button3
			$path_mod = selectmod()
			If $path_mod <> -1 Then
				_XMLCreateChildNodeWAttr ( "/TexModLauncher/Games/Game", "Mod", "Path" , $path_mod )
				stampamod()
			EndIf
			
		Case $Button7
			stampamodvuote()
			_XMLDeleteNode ( "/TexModLauncher/Games/Game/Mod")
			
		Case $Button5
			MsgBox(4096, "About", "Author Skrreeek - Version 0.1")

		Case $Button4
			Exit
			
		Case $Button6
			playgame()
			
	EndSwitch
WEnd

;;;
;; FUNZIONI
;;;

;
;
; Crea la struttura del config
;
;
Func setupconfig()
	_XMLCreateRootChild("Games")
	Local $aAttrib[1]
	$aAttrib[0] = "Path"
	Local $aValues[1]
	$aValues[0] = "empty"
	_XMLCreateChildNodeWAttr ( "/TexModLauncher", "Texmod", $aAttrib , $aValues )
	Local $aAttrib[2]
	$aAttrib[0] = "Name"
	$aAttrib[1] = "Path"

	Local $aValues[2]
	$aValues[0] = "empty"
	$aValues[1] = "empty"

	_XMLCreateChildNodeWAttr ( "/TexModLauncher/Games", "Game", $aAttrib , $aValues )
EndFunc

;
;
; Selezione exe texmod
;
;
Func selecttexmod()
	Local $message = "Select TexMod.exe"
	Local $var = FileOpenDialog($message, @WindowsDir & "\", "Executables (*.exe)", 1 + 4)
	If @error Then
		MsgBox(4096, "", "No File(s) chosen")
		Exit
	EndIf

	Local $path_texmod = $var
	FileFlush ($var)
	FileClose ($var)
	
	Return $path_texmod
EndFunc

;
;
; Selezione exe gioco
;
;
Func selectgame()
	Local $message = "Select your game exe"
	Local $var = FileOpenDialog($message, @WindowsDir & "\", "Executables (*.exe)", 1 + 4)
	If @error Then
		MsgBox(4096, "", "No File(s) chosen")
		Exit
	EndIf

	Local $path_gioco = $var
	FileFlush ($var)
	FileClose ($var)
	return $path_gioco
EndFunc

;
;
; Selezione mod
;
;
Func selectmod()
	
	$compare = StringCompare($path_texmod,"")
	If $compare = 0 Then
		MsgBox(4096, "Error", "You must set TexMod path before add mod")
		Return -1
	EndIf
	
	$compare = StringCompare($path_texmod,"empty")
	If $compare = 0 Then
		MsgBox(4096, "Error", "You must set TexMod path before add mod")
		Return -1
	EndIf

	$compare = StringCompare($path_game,"")
	If $compare = 0 Then
		MsgBox(4096, "Error", "You must set game path before add mod")
		Return -1
	EndIf

	$compare = StringCompare($path_game,"empty")
	If $compare = 0 Then
		MsgBox(4096, "Error", "You must set game path before add mod")
		Return -1
	EndIf
	
	Local $message = "Select your texture mod"
	Local $var = FileOpenDialog($message, @WindowsDir & "\", "TexMod File (*.tpf)", 1 + 4)
	If @error Then
		MsgBox(4096, "", "No File(s) chosen")
		Exit
	EndIf

	Local $path_mod = $var
	FileFlush ($var)
	FileClose ($var)
	Return $path_mod
EndFunc

;
;
; Stampa mods
;
;
Func stampamod()
	Local $modCount = _XMLGetNodeCount("/TexModLauncher/Games/Game/Mod")
	$c = 1
	While $c <= $modCount
		dim $aAttModName[$modCount],$aAttModVal[$modCount]
		dim $aMods[2]
		$aMods = _XMLGetAllAttrib("/TexModLauncher/Games/Game/Mod",$aAttModName,$aAttModVal,"[" & $c & "]")
		$mod_name = $aMods[1][1]
		GUICtrlSetData($List1,$mod_name)
		$c = $c + 1 
	WEnd
EndFunc

;
;
; Stampa mods vuote
;
;
Func stampamodvuote()
	GUICtrlSetData($List1, "")
EndFunc

;
;
; Play Game
;
;
Func playgame()
	
	$compare = StringCompare($path_texmod,"")
	If $compare = 0 Then
		MsgBox(4096, "Error", "You must set TexMod path before play game")
		Return
	EndIf
	
	$compare = StringCompare($path_texmod,"empty")
	If $compare = 0 Then
		MsgBox(4096, "Error", "You must set TexMod path before play game")
		Return
	EndIf

	$compare = StringCompare($path_game,"")
	If $compare = 0 Then
		MsgBox(4096, "Error", "You must set game path before play game")
		Return
	EndIf

	$compare = StringCompare($path_game,"empty")
	If $compare = 0 Then
		MsgBox(4096, "Error", "You must set game path before play game")
		Return
	EndIf
	
	Run($path_texmod , "")
	If @error Then
		MsgBox(4096, "", "TexMod exe not found")
		Return
	EndIf
	
	Do
		sleep(600)
	Until (WinExists("TexMod"))
		
	ControlClick("TexMod","","[CLASS:Button; INSTANCE:2]")

	Do
		sleep(600)
	Until (WinExists("Select Executable"))

	ControlSetText("Select Executable", "","[CLASS:Edit; INSTANCE:1]",$path_game)
	ControlClick("Select Executable", "","[CLASS:Button; INSTANCE:2]") 	

	Local $modCount = _XMLGetNodeCount("/TexModLauncher/Games/Game/Mod")
	$c = 1

	While $c <= $modCount
		dim $aAttModName[$modCount],$aAttModVal[$modCount]
		dim $aMods[2]
		$aMods = _XMLGetAllAttrib("/TexModLauncher/Games/Game/Mod",$aAttModName,$aAttModVal,"[" & $c & "]")
		$mod_name = $aMods[1][1]
		
		ControlClick("TexMod", "","[CLASS:Button; INSTANCE:12]")

		Do
			sleep(600)
		Until (WinExists("[CLASS:#32768]"))
		ControlSend("[CLASS:#32768]","","","{DOWN}")
		ControlSend("[CLASS:#32768]","","","{ENTER}")

		Do
			sleep(600)
		Until (WinExists("Select Texmod Packages to add."))
		
		
		ControlSetText("Select Texmod Packages to add.", "","[CLASS:Edit; INSTANCE:1]",$mod_name)
		
		ControlClick("Select Texmod Packages to add.", "","[CLASS:Button; INSTANCE:1]")
		$c = $c + 1
	WEnd	

	ControlClick("TexMod", "","[CLASS:Button; INSTANCE:11]")
	
	Return
EndFunc

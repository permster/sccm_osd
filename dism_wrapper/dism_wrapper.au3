#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=dism_x86.exe
#AutoIt3Wrapper_Outfile_x64=dism_AMD64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <_XMLDomWrapper.au3>

$sCmd = Chr(34) & @ScriptDir & "\dism2.exe" & Chr(34)
$sNewCmdLine = ""

If $CmdLine[0] > 0 Then
	If StringInStr($CmdLineRaw, "drivers.xml") Then
		;loop through parameters
		For $x = 1 To $CmdLine[0]
			;Named parameters
			If StringLeft($CmdLine[$x], 1) = "/" And StringInStr($CmdLine[$x],":", 0, -1) > 0 Then
				;windir (remove from cmd line)
				If StringLower(StringLeft($CmdLine[$x], StringInStr($CmdLine[$x],":", 0, 1))) = "/windir:" Then
					ConsoleWrite("Removing /windir: parameter" & @CR)
					ContinueLoop
				EndIf

				;apply-unattend
				If StringLower(StringLeft($CmdLine[$x], StringInStr($CmdLine[$x],":", 0, 1))) = "/apply-unattend:" Then
					ConsoleWrite("Removing /apply-unattend: parameter" & @CR)

					;unattend file path
					$sUnattendFile = StringTrimLeft($CmdLine[$x], StringInStr($CmdLine[$x], ":", StringLen($CmdLine[$x]), 1))
					ConsoleWrite("Unattend file: " & $sUnattendFile & @CR)

					;parse unattend file for driver path
					$sDriverPath = GetUnattendDriverPath($sUnattendFile)
					ConsoleWrite("Driver path (XML): " & $sDriverPath & @CR)

					;verifying driver path
					If StringLen($sDriverPath) = 0 Then
						ConsoleWrite("Using regex matching to get driver path" & @CR)
						$sDriverPath = GetUnattendDriverPathRegEx($sUnattendFile) ;fallback on regex matching
						ConsoleWrite("Driver path: " & $sDriverPath & @CR)
					EndIf

					;no driver path found
					If StringLen($sDriverPath) = 0 Then
						ConsoleWrite("Empty driver path, copying unattend file to " & @TempDir & @CR)
						FileCopy($sUnattendFile, @TempDir, 9)
					EndIf

					;append to new cmd line
					$sNewCmdLine &= " /Add-Driver /Driver:" & Chr(34) & $sDriverPath & Chr(34) & " /Recurse"
					ContinueLoop
				EndIf

				$sNewCmdLine &= " " & $CmdLine[$x]
			Else
				;un-named params
				$sNewCmdLine &= " " & $CmdLine[$x]
			EndIf
		Next
	EndIf
EndIf

If StringLen($sNewCmdLine) > 0 Then
	$sCmd &= $sNewCmdLine
Else
	$sCmd &= " " & $CmdLineRaw
EndIf

ConsoleWrite("Running command: " & $sCmd & @CR)
Exit(RunWait($sCmd))



Func StripDriverPath($sString)
	;strip carriage returns and leading/trailing spaces
	Return  StringStripWS(StringStripCR($sString), 3)
EndFunc

Func GetUnattendDriverPathRegEx($sFile)
	Local $aLines = FileReadToArray($sFile)
	If @error Then Return SetError(1, 0, "")

	For $x = 0 To UBound($aLines)-1
		$aPath = StringRegExp($aLines[$x], "<Path>(.*?)</Path>", 1)
		If @error Then ContinueLoop
		Return StripDriverPath($aPath[0])
	Next
	Return SetError(2, 0, "")
EndFunc

Func GetUnattendDriverPath($sFile)
	Local $sXmlNS, $sRootXPath, $aPath

	$sXmlNS = '"urn:schemas-microsoft-com:unattend"'
	$sRootXPath = "//MyNS:Path"

	_XMLFileOpen($sFile, 'xmlns=' & $sXmlNS)
	If @error Then Return SetError(@error, 0, "")

	$objDoc.setProperty("SelectionNamespaces", 'xmlns:MyNS=' & $sXmlNS)
	$aPath = _XMLGetValue($sRootXPath)
	If @error Then Return SetError(@error, 1, "")

	If Not IsArray($aPath) Then Return SetError(3, 2, "")
	Return StripDriverPath($aPath[1])
EndFunc

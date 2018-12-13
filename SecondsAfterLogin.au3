#include-once
#include <AD.au3>
#include <Date.au3>

; #FUNCTION# ====================================================================================================================
; Name ..........: _SecondsAfterLogin
; Description ...: Returns how many seconds are gone since last login
; Syntax ........: _SecondsAfterLogin()
; Parameters ....: None
; Return values .: Success - Integer of seconds
;				   Failure - 0, sets @error to 1
; Author ........: Conrad Zelck
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SecondsAfterLogin()
	Local $sDate
	Local $iSec
	$sDate = __GetLogonTime() ; UTC
	If @error Then
		$sDate = __GetLogonTime_AD() ; local time
		If @error Then Return SetError(1, 0, 0)
	Else
		$sDate = __LocalTime($sDate) ; UTC to local time
	EndIf
	$iSec = __TimeDifference($sDate)
	Return $iSec
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _WaitSecAfterLogin
; Description ...: Sleeps the programm if $iWaitSecAfterLogin is greater then seconds after last login
; Syntax ........: _WaitSecAfterLogin([$iWaitSecAfterLogin = 180])
; Parameters ....: $iWaitSecAfterLogin  - [optional] an integer value. Default is 180.
; Return values .: None
; Author ........: Conrad Zelck
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WaitSecAfterLogin($iWaitSecAfterLogin = 180)
	Local $iSec = _SecondsAfterLogin()
	If Not @error Then
		While $iSec < $iWaitSecAfterLogin
			TraySetToolTip("Wait " & $iWaitSecAfterLogin - $iSec & " seconds.")
			Sleep(1000)
			$iSec += 1
		WEnd
		TraySetToolTip()
	EndIf
EndFunc


#region - INTERNAL_USE_ONLY
Func __GetLogonTime($sUserName = @UserName, $sComputerName = @ComputerName) ; Idea by trancexx: http://www.autoitscript.com/forum/topic/113611-if-isadmin-not-detected-as-admin/
    Local $aRet = DllCall("netapi32.dll", "long", "NetUserGetInfo", "wstr", $sComputerName, "wstr", $sUserName, "dword", 11, "ptr*", 0)
    If @error Or $aRet[0] Then Return SetError(1, 0, 0)
    Local $sSeconds = DllStructGetData(DllStructCreate("ptr;ptr;ptr;ptr;dword;dword;dword;ptr;ptr;dword;dword;dword;dword;ptr;dword;ptr;dword;dword;byte;dword", $aRet[4]), 10)
    DllCall("netapi32.dll", "long", "NetApiBufferFree", "ptr", $aRet[4])
    Local $sLastLogon = _DateAdd('s', Number($sSeconds), "1970/01/01 00:00:00")
    Return $sLastLogon
EndFunc

Func __GetLogonTime_AD()
	Local $iSuccess = _AD_Open()
	If $iSuccess = 1 Then
		Local $sDate = _AD_GetLastLoginDate()
		$sDate = __NumberDate_StringDate($sDate)
		_AD_Close()
		Return $sDate
	Else
		Return SetError(1, 0, 0)
	EndIf
EndFunc

Func __NumberDate_StringDate($sDate)
	Local $y, $m, $d, $h, $min, $s
	$y = StringMid($sDate,1, 4)
	$m = StringMid($sDate,5, 2)
	$d = StringMid($sDate,7, 2)
	$h = StringMid($sDate,9, 2)
	$min = StringMid($sDate,11, 2)
	$s = StringMid($sDate,13, 2)
	$sDate = $y & "/" & $m & "/" & $d & " " & $h & ":" & $min & ":" & $s
	Return $sDate
EndFunc

Func __LocalTime($sDate)
	Local $iTimeZoneOffset
	Local $aTimeZone = _Date_Time_GetTimeZoneInformation()
    If $aTimeZone[0] <> 2 Then
        $iTimeZoneOffset = ($aTimeZone[1]) * -1
    Else
        $iTimeZoneOffset = ($aTimeZone[1] + $aTimeZone[7]) * -1
    EndIf
	$iTimeZoneOffset /= 60 ; in hours
	Local $sHour = StringMid($sDate, 12, 2)
	$sHour += $iTimeZoneOffset
	$sDate = StringLeft($sDate, 11) & $sHour & StringRight($sDate, 6)
	Return $sDate
EndFunc

Func __TimeDifference($sDate)
	Local $sNow = _NowCalc()
	Local $sDiff = _DateDiff("s", $sDate, $sNow)
	Local $iDiff = Number($sDiff)
	Return $iDiff
EndFunc
#endregion - INTERNAL_USE_ONLY
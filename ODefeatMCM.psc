Scriptname ODefeatMCM extends ski_configbase  

Event OnConfigInit()
    ; Stuff
endEvent

Event OnPageReset()
    ;Stuff
EndEvent

Event OnOptionSelect(int Option)
    ;Stuff
EndEvent

Event OnOptionHighlight(Int Option)
    ;Stuff
EndEvent

; Modified version of the same function from Ostim, just with manual control.
Function AddColoredHeader(String In, String color = "Pink")
	String Blue = "#6699ff"
	String Pink = "#ff3389"
    If (color == "pink")
        Color = Pink
    ElseIf (color == "blue")
        Color = Blue
    Else
        Color = Pink
    EndIf
	AddHeaderOption("<font color='" + Color +"'>" + In)
EndFunction

; This just makes life easier sometimes.
Function WriteLog(String OutputLog, bool error = false)
    MiscUtil.PrintConsole("OStrap: " + OutputLog)
    Debug.Trace("OStrap: " + OutputLog)
    if (error == true)
        Debug.Notification("Ostrap: " + OutputLog)
    endIF
EndFunction
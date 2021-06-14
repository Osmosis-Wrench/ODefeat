Scriptname ODefeatMCM extends nl_mcm_module  

ODefeatMain property main auto

Event OnInit()
    RegisterModule("core")
endEvent

Event OnPageInit()
    SetModName("ODefeat")
    SetLandingPage("Core")    
endEvent

event OnPageDraw()
    AddToggleOptionST("CheatModeEnabledState", "Enable Cheat Mode", main.cheatMode)
endEvent


state CheatModeEnabledState
    event OnSelectST(string state_id)
        main.cheatMode = !main.cheatMode
        SetToggleOptionValueST(main.cheatMode)
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("")
    endEvent
endState

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
    MiscUtil.PrintConsole("ODefeat: " + OutputLog)
    Debug.Trace("ODefeat: " + OutputLog)
    if (error == true)
        Debug.Notification("ODefeat: " + OutputLog)
    endIF
EndFunction
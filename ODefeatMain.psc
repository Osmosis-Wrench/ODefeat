Scriptname ODefeatMain extends Quest  
ODefeatMCM Property ODefeatMCM Auto
OsexIntegrationMain Property Ostim Auto

Function OnInit()
    Startup()
EndFunction

Function Startup()
    ; Register for keypress events. I'm not sure what all of these do yet.
    RegisterForKey(34) ;G - attacks
	RegisterForKey(37) ;K - enslaves
	RegisterForKey(207) ;End - opens a menu?

    RegisterForKey(42) ;leftshift - Seems to be related to a RunningAttack function. 
	RegisterForKey(54) ;rightshift - Seems to be related to a RunningAttack function. 
	RegisterForKey(57) ;space - Seems to be related to a RunningAttack function. 

    ; Attack status information.
    attackStatus = 0 ;what do the other numbers mean?
    attackComplete = False ;
    attackRunning = False ;What is this for?

EndFunction

Event onKeyDown(int keyCode)
    if (Utility.IsInMenuMode())
        return
    Elseif (keyCode == 34) ; G
        ;Try to perform attack, or strip dead npc?
    Elseif (keyCode == 34) ; K
        ;Enslave target.
    Elseif (keyCode == 34) ; End
        ;opens a data menu?
    EndIf
    
    ; Find out what RunningAttack is exactly.
    if (RunningAttack)
        if (keyCode == 34) ; Left-shift

        Elseif (keyCode == 34) ; Right-shift

        Elseif (keyCode == 34) ; Spacebar
        
        EndIf
    EndIF
EndEvent
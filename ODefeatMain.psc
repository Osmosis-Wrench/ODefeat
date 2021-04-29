Scriptname ODefeatMain extends Quest  
Actor Property PlayerRef Auto  
ODefeatMCM Property ODefeatMCM Auto
OsexIntegrationMain Property Ostim Auto

Function onInit()
    Startup()
EndFunction

Function startup()
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
        actor npc = Game.GetCurrentCrosshairRef() as Actor ; find out if there is a faster way to do this with properties.
        if (!npc.isDead())
            attemptAttack(PlayerRef, NPC)
        elseif (npc.isdead())
            ;Ostim strip? I guess?
        endif
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

;  ███╗   ███╗ █████╗ ██╗███╗   ██╗
;  ████╗ ████║██╔══██╗██║████╗  ██║
;  ██╔████╔██║███████║██║██╔██╗ ██║
;  ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
;  ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
;  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
; ODefeat Main logic.

Function attemptAttack(Actor attacker, actor victim)
    ; Attempt to start attack minigame.
EndFunction

Function runStruggleAnim(Actor attacker, actor victim, bool animate = true, bool victimStayDown = false, bool noIdle = false)
    ; Run struggle animation.
EndFunction

Function StripActor(Actor target)

EndFunction

; ███╗   ███╗██╗███████╗ ██████╗
; ████╗ ████║██║██╔════╝██╔════╝
; ██╔████╔██║██║███████╗██║     
; ██║╚██╔╝██║██║╚════██║██║     
; ██║ ╚═╝ ██║██║███████║╚██████╗
; ╚═╝     ╚═╝╚═╝╚══════╝ ╚═════╝
; ODefeat misc functions.

Bool Function getTrauma(Actor target, bool enter = true)
    ; Returns whether actor is in Trauma? Enter might imply this does both get and set.
EndFunction

Bool Function getCalm(Actor target, bool dontMove = true, bool enter = true)
    ; Returns whether actor is calmed? Enter might imply this does both get and set.
endFunction

Bool Function isValidAttackTarget(actor target)
    ; Returns if actor is valid attack target.
endFunction

Float Function getActorAttackDificulty(actor target)
    ; Return a float of the dificulty of the attack minigame, based off the actor pased in.
endFunction


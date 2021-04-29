Scriptname ODefeatMain extends Quest  
Actor Property PlayerRef Auto  
ODefeatMCM Property ODefeatMCM Auto
OsexIntegrationMain Property Ostim Auto

;  ██████╗ ██████╗ ███████╗███████╗███████╗ █████╗ ████████╗
; ██╔═══██╗██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗╚══██╔══╝
; ██║   ██║██║  ██║█████╗  █████╗  █████╗  ███████║   ██║   
; ██║   ██║██║  ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██║   ██║   
; ╚██████╔╝██████╔╝███████╗██║     ███████╗██║  ██║   ██║   
;  ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   
; ODefeat Main Script

Function onInit()
    Startup()
EndFunction

Function startup()
    ; Register for keypress events. I'm not sure what all of these do yet.
    RegisterForKey(34) ;G - attacks
	RegisterForKey(37) ;K - enslaves
	RegisterForKey(207) ;End - opens a menu?

    ; Attack status information.
    attackStatus = 0 ; What do the other numbers mean?
    attackComplete = False ; Attack has finshed completely.
    attackRunning = False ; Attack is in progress.
EndFunction

Event onKeyDown(int keyCode)
    if (Utility.IsInMenuMode())
        return
    Elseif (keyCode == 34) ; G
        ;Try to perform attack, or strip dead npc?
        attackKeyHandler()
    Elseif (keyCode == 34) ; K
        ;Enslave target.
        enslaveKeyHander()
    Elseif (keyCode == 34) ; End
        ;opens a data menu?
        menuKeyHandler()
    EndIf
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
    if (isValidAttackTarget(victim) || AttackRunning)
        return
    endif

    if (attacker == PlayerRef)
        PlayerAttacker = True
    Else
        PlayerAttacker = false
    endif

    attacker.SheatheWeapon()
    victim.SheatheWeapon()
    victimHasCrimeFaction = victim.GetCrimeFaction() as bool
    warmupTime = 20

    ;Setup Bar percents, also need to investigate bars.
    if (PlayerAttacker)
        float difficulty = getActorAttackDificulty(victim)
        bar.setPercent(0.05)
        AttackStatus = 5.0
    Else
        float difficulty = getActorAttackDificulty(attacker)
        bar.setPercent(0.80)
        AttackStatus = 80.0
        PlayerRef.SetDontMove(True)
        ToggleCombat()
    EndIf

    attackComplete = False

    while (!attackComplete)
        if (warmup > 0) ; A little bit of time at the begining for getting ready.
            ;do nothing for a moment
        else ; do the main minigame loop.
            if (attackStatus <= 0) ; If attackStatus bar is empty, exit loop.
                attackComplete = True
                victory = false
            elseif (attackStatus >= 100) ; If attackStatus bar is full, exit loop.
                attackComplete = True
                victory = True
            endIf

            ;I'm not sure why this is done yet?
            if (PlayerAttacker)
                attackStatus += cycleCount - difficulty
            else
                attackStatus -= cylceCount - difficulty
            endif

            bar.SetPercent(attackStatus / 100.0)

            If PlayerAttacker
                if     (stripStage 0 == && attackStatus >= 20) ; helmet
                    StripItem(Victim, victim.GetWornForm(0x00000002))
                elseif (stripStage 1 == && attackStatus >= 40) ; gauntlet
                    StripItem(Victim, victim.GetWornForm(0x00000008))
                elseif (stripStage 2 == && attackStatus >= 60) ; feet
                    StripItem(Victim, victim.GetWornForm(0x00000080)
                elseif (stripStage 3 == && attackStatus >= 80) ; left hand
                    StripItem(Victim, victim.GetEquippedObject(0) as form)
                elseif (stripStage 4 == && attackStatus >= 90) ; right hand
                    StripItem(Victim, victim.GetEquippedObject(1) as form)
                elseif (stripStage 5 == && attackStatus >= 95) ; armor
                    StripItem(Victim, victim.GetWornForm(0x00000004))
                endif
            Else
                if     (stripStage 0 == && attackStatus >= 84) ; helmet
                    StripItem(Victim, victim.GetWornForm(0x00000002))
                elseif (stripStage 1 == && attackStatus >= 87) ; gauntlet
                    StripItem(Victim, victim.GetWornForm(0x00000008))
                elseif (stripStage 2 == && attackStatus >= 91) ; feet
                    StripItem(Victim, victim.GetWornForm(0x00000080)
                elseif (stripStage 3 == && attackStatus >= 94) ; left hand
                    StripItem(Victim, victim.GetEquippedObject(0) as form)
                elseif (stripStage 4 == && attackStatus >= 96) ; right hand
                    StripItem(Victim, victim.GetEquippedObject(1) as form)
                elseif (stripStage 5 == && attackStatus >= 98) ; armor
                    StripItem(Victim, victim.GetWornForm(0x00000004))
                endif
            EndIf
        endIf
        Utility.Wait(0.1)
    endWhile

EndFunction

Function runStruggleAnim(Actor attacker, actor victim, bool animate = true, bool victimStayDown = false, bool noIdle = false)
    ; Run struggle animation.
EndFunction


; ██╗  ██╗███████╗██╗   ██╗██████╗ ██╗███╗   ██╗██████╗ ███████╗
; ██║ ██╔╝██╔════╝╚██╗ ██╔╝██╔══██╗██║████╗  ██║██╔══██╗██╔════╝
; █████╔╝ █████╗   ╚████╔╝ ██████╔╝██║██╔██╗ ██║██║  ██║███████╗
; ██╔═██╗ ██╔══╝    ╚██╔╝  ██╔══██╗██║██║╚██╗██║██║  ██║╚════██║
; ██║  ██╗███████╗   ██║   ██████╔╝██║██║ ╚████║██████╔╝███████║
; ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝
; ODefeat keybind functions.

Function attackKeyHandler()
    actor npc = Game.GetCurrentCrosshairRef() as Actor ; find out if there is a faster way to do this with properties.
    if (!npc.isDead())
        attemptAttack(PlayerRef, NPC)
    elseif (npc.isdead())
        StripActor(npc)
    endif
EndFunction
    
Function enslaveKeyHander()
    ;Stuff
EndFunction

Function menuKeyHandler()
    ;Stuff
EndFunction


; ███╗   ███╗██╗███████╗ ██████╗
; ████╗ ████║██║██╔════╝██╔════╝
; ██╔████╔██║██║███████╗██║     
; ██║╚██╔╝██║██║╚════██║██║     
; ██║ ╚═╝ ██║██║███████║╚██████╗
; ╚═╝     ╚═╝╚═╝╚══════╝ ╚═════╝
; ODefeat misc functions.

Function toggleCombat() 
    ; Huge hack.
    ConsoleUtil.ExecuteCommand("tcai")
EndFunction

Bool Function getTrauma(Actor target, bool enter = true)
    ; Returns whether actor is in Trauma? Enter might imply this does both get and set.
    return true
EndFunction

Bool Function getCalm(Actor target, bool dontMove = true, bool enter = true)
    ; Returns whether actor is calmed? Enter might imply this does both get and set.
    return true
endFunction

Bool Function isValidAttackTarget(actor target)
    ; Returns if actor is valid attack target.
    return true
endFunction

Float Function getActorAttackDificulty(actor target)
    ; Return a float of the dificulty of the attack minigame, based off the actor pased in.
    float ret = 1.0
    return ret
endFunction

Function stripActor(Actor target)
    ; Strip targeted actor.
EndFunction

Function stripItem(actor target, string item)
    ; Strip a specific item from an actor.
    if item
        target.dropObject(item)
    endIf
endFunction
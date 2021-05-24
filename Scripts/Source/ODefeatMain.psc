Scriptname ODefeatMain extends Quest  
Actor Property PlayerRef Auto  
ODefeatMCM Property ODefMCM Auto
OsexIntegrationMain Property Ostim Auto

ObjectReference[] property droppedItems auto
faction property calmFaction auto
Package Property DoNothing Auto
Sound property FXMeleePunchLargeS auto
 
Sound property FXMeleePunchMediumS auto ; TODO SET  - NOT SET YET

Spell property ODefeatSpell auto 
MagicEffect property ODefeatMagicEffect auto

ObjectReference Property posref Auto
int stripStage
Float attackStatus
bool attackComplete
bool attackRunning
Osexbar defeatBar

Actor AttackingActor
Actor VictimActor

int nextKey ; rename this?
int cycleCount

bool PlayerAttacker


int warmupTime

bool cheatMode = true ;TODO - disable for release



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
    RegisterForKey(42) ;leftshift - Minigame key 1
    RegisterForKey(54) ;rightshift - Minigame key 2
    RegisterForKey(57) ;Space - exit minigame fast

    ; Attack status information.
    attackStatus = 0 ; What do the other numbers mean?
    attackComplete = False ; Attack has finshed completely.
    attackRunning = False ; Attack is in progress.

    ;RegisterForModEvent("ostim_end", "OstimEnd")

    defeatBar = (Self as Quest) as Osexbar
    

    droppedItems = PapyrusUtil.ObjRefArray(6, none)

    posref = playerref.PlaceAtMe((Quest.GetQuest("0SA") as _oOmni).OBlankStatic) as ObjectReference

    InitBar(defeatBar)
    Debug.notification("ODefeat installed")
EndFunction

Event onKeyDown(int keyCode)
    if (Utility.IsInMenuMode())
        return
    Elseif (keyCode == 34) ; G
        ;Try to perform attack, or strip dead npc?
        attackKeyHandler()
    EndIf

    if AttackRunning
        if keyCode == 42 && nextKey == 0
            nextKey = 1

        elseif keyCode == 54 && nextKey == 1
            nextKey = 0
            cycleDone()
        elseif keyCode == 57
            cycleCount = -200
        endif
    endif
EndEvent

Function InitBar(OSexBar setupBar)
    setupBar.HAnchor = "left"
    setupBar.VAnchor = "bottom"
    setupBar.X = 495
    setupBar.Y = 600
    setupBar.Alpha = 100.0
    setupBar.FlashColor = 0x000000
    setupBar.SetPercent(50.0)
    ;setupBar.FillDirection = "center"
    ;setupBar.SetColors(0xFE1B61, 0xB0B0B0) 
    setupBar.SetColors(0xFF96e6, 0x9F1666)

    Utility.Wait(2)

    SetBarVisible(setupBar, False)
endFunction

Function SetBarVisible(Osexbar setupBar, Bool Visible)
	If (Visible)
		setupBar.FadeTo(100.0, 1.0)
		setupBar.FadedOut = False
	Else
		setupBar.FadeTo(0.0, 1.0)
		setupBar.FadedOut = True
	EndIf
EndFunction

;  ███╗   ███╗ █████╗ ██╗███╗   ██╗
;  ████╗ ████║██╔══██╗██║████╗  ██║
;  ██╔████╔██║███████║██║██╔██╗ ██║
;  ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
;  ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
;  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
; ODefeat Main logic.

Function attemptAttack(Actor attacker, actor victim)
    ; Attempt to start attack minigame.
    if (!isValidAttackTarget(victim) || AttackRunning)
        return
    endif

    If ostim.IsActorActive(victim)
        ostim.EndAnimation(false)
    endif 

    attackRunning = true 

    AttackingActor = attacker 
    VictimActor = victim 

    PlayerAttacker = (attacker == PlayerRef) 

    attacker.SheatheWeapon()
    victim.SheatheWeapon()
    float difficulty
    warmupTime = 20
    stripStage

    ;Setup Bar percents, also need to investigate bars.
    if (PlayerAttacker)
        difficulty = getActorAttackDifficulty(victim)
        defeatBar.setPercent(0.05)
        AttackStatus = 5.0
    Else
        difficulty = getActorAttackDifficulty(attacker)
        defeatBar.setPercent(0.80)
        AttackStatus = 80.0
        PlayerRef.SetDontMove(True)
        ToggleCombat()
    EndIf

    attackComplete = False
    cycleCount = 0
    bool victory
    nextKey = 0
    int difficultyCounter = 0

    SetBarVisible(defeatBar, true)

    RunStruggleAnim(attacker, victim) 
    
    while (!attackComplete)
        if (warmupTime > 0) ; A little bit of time at the begining for getting ready.
            if (cycleCount > 0)
                warmupTime = 0
            else
                warmupTime -= 1
            endif
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
                attackStatus -= cycleCount - difficulty
            endif

            defeatBar.SetPercent(attackStatus / 100.0)
            cycleCount = 0
            difficultyCounter += 1

            if difficultyCounter >= 50 ;boost difficulty if slow
                difficulty += 1
                difficultyCounter = 0
            endif
            
            ; I want to put all this in a simple function, rather than have this mess. Maybe work out a way to generate this dynamically.
            If (PlayerAttacker)
                if     (stripStage == 0 && attackStatus >= 20) ; helmet
                    StripItem(Victim, victim.GetWornForm(0x00000002))
                elseif (stripStage == 1 && attackStatus >= 40) ; gauntlet
                    StripItem(Victim, victim.GetWornForm(0x00000008))
                elseif (stripStage == 2 && attackStatus >= 60) ; feet
                    StripItem(Victim, victim.GetWornForm(0x00000080))
                elseif (stripStage == 3 && attackStatus >= 80) ; left hand
                    StripItem(Victim, victim.GetEquippedObject(0) as form)
                elseif (stripStage == 4 && attackStatus >= 90) ; right hand
                    StripItem(Victim, victim.GetEquippedObject(1) as form)
                elseif (stripStage == 5 && attackStatus >= 95) ; armor
                    StripItem(Victim, victim.GetWornForm(0x00000004))
                endif
            Else
                if     (stripStage == 0 && attackStatus >= 84) ; helmet
                    StripItem(Victim, victim.GetWornForm(0x00000002))
                elseif (stripStage == 1 && attackStatus >= 87) ; gauntlet
                    StripItem(Victim, victim.GetWornForm(0x00000008))
                elseif (stripStage == 2 && attackStatus >= 91) ; feet
                    StripItem(Victim, victim.GetWornForm(0x00000080))
                elseif (stripStage == 3 && attackStatus >= 94) ; left hand
                    StripItem(Victim, victim.GetEquippedObject(0) as form)
                elseif (stripStage == 4 && attackStatus >= 96) ; right hand
                    StripItem(Victim, victim.GetEquippedObject(1) as form)
                elseif (stripStage == 5 && attackStatus >= 98) ; armor
                    StripItem(Victim, victim.GetWornForm(0x00000004))
                endif
            EndIf
        endIf
        Utility.Wait(0.1)
    endWhile

    SetBarVisible(defeatBar, false)
    
    ; On Struggle End
    if (Victory)
        runStruggleAnim(attacker, victim, false, true)
        StruggleDontMove(attacker, victim, playerattacker, true)
        if (PlayerAttacker)
            doTrauma(victim)
        else
            PlayerAttackFailedEvent(attacker)
        endif
        StruggleDontMove(attacker, victim, playerattacker, false)
    else 
        runStruggleAnim(attacker, victim, false, false, true)
        Attacker.PushActorAway(victim, 0) ;seems to fail on some actors?
        Victim.PushActorAway(Attacker, 3)
        FXMeleePunchLargeS.Play(Attacker)
        if (PlayerAttacker)
            Game.triggerscreenblood(20)
            victim.StartCombat(attacker)
			victim.DrawWeapon()
        else
            attacker.StartCombat(attacker)
			attacker.DrawWeapon()
        endif
    endif

    if (!PlayerAttacker)
        PlayerRef.SetDontMove(false)
        Utility.Wait(2.0)
        toggleCombat()
    endIf

    attackRunning = false
EndFunction

Function cycleDone() 
    cycleCount += 10
    if ostim.chanceRoll(33)
        Game.ShakeCamera(PlayerRef, afStrength = 1, afDuration = 0.3)

        
            actor damaged
            int damage

            if ostim.chanceRoll(66) ;this fucking shit makes no sense
                damaged = attackingactor
                damage = 1

                if !PlayerAttacker
                    Game.triggerscreenblood(1)
                endif

                
            Else
                damaged = VictimActor
                damage = 2

                if PlayerAttacker
                    Game.triggerscreenblood(2)
                endif

        
            endif
            if damaged.GetActorValue("health") > 2
                damaged.damageav("health", damage)
            endif
            FXMeleePunchMediumS.Play(damaged)
    endif
endfunction 

Function struggleDontMove(actor attacker, actor victim, bool isPlayerAttacker, bool moveEnabled)
    if (isPlayerAttacker)
        victim.SetDontMove(moveEnabled)
    else
        attacker.SetDontMove(moveEnabled)
    endif
endFunction

Function runStruggleAnim(Actor attacker, actor victim, bool animate = true, bool victimStayDown = false, bool noIdle = false)
    ; Run struggle animation.
    if (animate)
        struggleActorPreventMove(attacker, true)
        struggleActorPreventMove(victim, true)

        ; Should we use the old code for struggle scene, or use Ostim code?
        ; For now I'll use old code.

        if (attacker == PlayerRef) ; Move scene to the location of the player.
            (posRef).MoveTo(attacker)
        else
            (posRef).MoveTo(Victim)
        endif

		float[] CenterLocation = new float[6] ; Get coords of posref exactly.
		CenterLocation[0] = posref.GetPositionX()
		CenterLocation[1] = posref.GetPositionY()
		CenterLocation[2] = posref.GetPositionZ()
		CenterLocation[3] = posref.GetAngleX()
		CenterLocation[4] = posref.GetAngleY()
		CenterLocation[5] = posref.GetAngleZ()

        if (Attacker == PlayerRef) ; place and align attacker
            CenterLocation[3] = 21 ; I think this is to align the actors to the same angle?
            CenterLocation[4] = 0
            CenterLocation[5] = 240

            int offset = OStim.RandomInt(20, 30)
            Attacker.SetPosition(CenterLocation[0], CenterLocation[1] - 15, CenterLocation[2] + 6)
            Attacker.SetAngle(CenterLocation[3] - 60, CenterLocation[4], CenterLocation[5] - offset)

            ConsoleUtil.ExecuteCommand("player.setangle x 10") ; first person camera allignment
        else
            Attacker.SetPosition(CenterLocation[0], CenterLocation[1], CenterLocation[2] + 6)
            Attacker.SetAngle(CenterLocation[3], CenterLocation[4], CenterLocation[5])
        endif

        ; Place and align victim.
        victim.SetAngle(CenterLocation[3], CenterLocation[4], CenterLocation[5])
        victim.SetPosition(CenterLocation[0], CenterLocation[1], CenterLocation[2] + 5)

        ; disable collision
        Victim.TranslateTo(0.0, 0.0, 0.0, 90.0, 90.0, 90.0, 1.0, 0.000000001)
        attacker.TranslateTo(0.0, 0.0, 0.0, 90.0, 90.0, 90.0, 1.0, 0.000000001)

        ; Parent actors to posref.
        Victim.SetVehicle(posref)
        Attacker.SetVehicle(posref)

        ; Start Struggle anim.
        Debug.SendAnimationEvent(Victim, "Leito_nc_missionary_A1_S1")
        Debug.SendAnimationEvent(Attacker, "Leito_nc_missionary_A2_S1")

        

    else
        struggleActorPreventMove(attacker, false)
        struggleActorPreventMove(victim, false)

        Victim.SetVehicle(none)
        Attacker.SetVehicle(none)

        ;reenable collision
        victim.StopTranslation()
        attacker.StopTranslation()

        if (!noIdle)
            Debug.SendAnimationEvent(attacker, "IdleForceDefaultState")
           ;Debug.SendAnimationEvent(Victim, "IdleForceDefaultState")
        endif

        if !victimStayDown
            Debug.SendAnimationEvent(victim, "IdleForceDefaultState")
        endif
    endif
EndFunction

Function struggleActorPreventMove(Actor act, bool preventMove)
    if (PreventMove)
        if (act == PlayerRef)
            Game.SetPlayerAiDriven()
            Game.ForceThirdPerson()
        else
            ActorUtil.AddPackageOverride(act, DoNothing, 100, 1)
            act.EvaluatePackage()
            act.SetRestrained(true)
            act.SetDontMove(true)
        endif

    else
        if (act == PlayerRef)
            Game.SetPlayerAiDriven(False)
        else
            act.SetRestrained(False)
            act.SetDontMove(false)
            ActorUtil.RemovePackageOverride(act, DoNothing)
        endif
    endif
EndFunction

Function playerAttackFailedEvent(actor Act)
    if ostim.AnimationRunning() && !ostim.IsPlayerInvolved() ;clear background threads
        ostim.EndAnimation(false)
        Utility.Wait(2) 
    endif 
    StartScene(act, playerref)
endFunction

Function StartScene(actor Dom, actor Sub)
    Ostim.StartScene(dom, sub, Aggressive = True, AggressingActor = dom)
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
    
    if ostim.IsActorActive(playerref)
        return 
    endif 

    if (!npc.isDead())
        If isActorHelpless(npc)
            StartScene(playerref, npc)
        else
            attemptAttack(PlayerRef, NPC)
        endif
    else
        StripActor(npc)
    endif
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

Bool Function doTrauma(Actor target, bool enter = true)
    if (target.IsDead() || Target == PlayerRef)
        return false
    endif
    doCalm(target)
    if (Enter)
        Target.EvaluatePackage() ; Why do we do this? We aren't applying any new packages.
        Debug.SendAnimationEvent(Target, "IdleWounded_02")
        Utility.Wait(1)

        if !Target.HasMagicEffect(ODefeatMagicEffect)       
                ODefeatSpell.cast(Target)
        endif

        int Tries = 3
        float X
        float newX
        X = Target.X

        while (Tries != 0)
            Utility.Wait(1)
            newX = Target.X
            if (newX == X)
                Tries = 0
            Else
                Debug.SendAnimationEvent(Target, "IdleWounded_02")
                x - newX
                Tries -= 1
            endif  
        endWhile
        return true
    else
       ; Debug.SendAnimationEvent(target, "DefeatTraumaExit")
        doCalm(Target, Enter = False)
        return true
    endif
    return false
EndFunction

Bool Function doCalm(Actor target, bool dontMove = true, bool enter = true)
    if (Enter)
        if (!Target.IsInFaction(CalmFaction))
            Target.AddToFaction(CalmFaction)
            Target.StopCombat()
            Target.StopCombatAlarm()
            if (dontMove)
                ActorUtil.AddPackageOverride(Target, DoNothing, 100, 1)
                Target.EvaluatePackage()
            endif
            return true
        else
            target.StopCombatAlarm()
        endif
    else
        Target.RemoveFromFaction(CalmFaction)
        if (dontMove)
            ActorUtil.RemovePackageOverride(Target, DoNothing)
            Target.EvaluatePackage()
        endif
        return true
    endif
    return false
endFunction

Bool Function isValidAttackTarget(actor target)
    ; Returns if actor is valid attack target.
    If (!Target.IsChild())
        If (Target.HasKeywordString("ActorTypeNPC"))
            If (!Target.HasKeywordString("ActorTypeCreature"))
                Return True
            EndIf
        EndIf
    EndIf
    return false
endFunction

Bool Function isActorHelpless(actor target)
    return target.HasMagicEffect(ODefeatMagicEffect)
endFunction

Function stripActor(Actor target)
    form chest = target.GetWornForm(0x00000004)
	if (chest)
		stripItem(target, chest, false)
		Return 
	endif
	form helmet = target.GetWornForm(0x00000002)
	if (helmet)
		stripItem(target, helmet, false)
		Return 
	endif
	form boots = target.GetWornForm(0x00000080)
	if (boots)
		stripItem(target, boots, false)
		Return 
	endif
	form hands = target.GetWornForm(0x00000008)
	if (hands)
		stripItem(target, hands, false)
		Return 
	endif
EndFunction

Function stripItem(actor target, form item, bool doImpulse = true)
    ; Strip a specific item from an actor.
    if (item)
        objectreference droppedItem = target.dropObject(item)
        droppedItem.SetPosition(DroppedItem.GetPositionX(), DroppedItem.GetPositiony(), DroppedItem.GetPositionz() + 64)
        if (doImpulse)
            droppedItem.applyHavokImpulse(Utility.RandomFloat(-2.0, 2.0), Utility.RandomFloat(-2.0, 2.0), Utility.RandomFloat(0.2, 1.8), Utility.RandomFloat(10, 50))
        endif
        droppedItems[stripStage] = DroppedItem
    endif
    stripStage += 1
endFunction

Float Function getActorAttackDifficulty(actor target)
    ; Return a float of the Difficulty of the attack minigame, based off the actor pased in.

    if cheatMode 
        return 0
    endif 

    float ret = 0
    float levelRatio = ((target.GetLevel() as Float)/(playerref.GetLevel() as Float)) * 100
    if (levelRatio > 140)
        ret = 10.0
    elseif (levelRatio > 125)
        ret = 9.0
    elseif (levelRatio > 100)
        ret = 8.0
    elseif (levelRatio > 70)
        ret = 7.5
    elseif (levelRatio > 35)
        ret = 6.5
    endif
    if (target.IsBleedingOut())
        ret -= 7.5
    else
        ret -= ((100.0 - (target.GetActorValuePercentage("Health") * 100)) / 40.0)
    endif
    if (!playerRef.IsDetectedBy(target))
        ret -= 1.0
    endif
    if (!target.IsInCombat())
        ret -= 1.0
    endif
    if target.GetSleepState() == 3
		ret -= 1
	endif
    if (ret < 5.0)
        ret = 5.0
    endif
    return ret
endFunction

Event OStimEnd(string eventName, string strArg, float numArg, Form sender)
    
EndEvent 

; This just makes life easier sometimes.
Function WriteLog(String OutputLog, bool error = false)
    MiscUtil.PrintConsole("ODefeat: " + OutputLog)
    Debug.Trace("ODefeat: " + OutputLog)
    if (error == true)
        Debug.Notification("ODefeat: " + OutputLog)
    endIF
EndFunction
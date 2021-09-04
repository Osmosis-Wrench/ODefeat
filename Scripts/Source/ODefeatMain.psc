Scriptname ODefeatMain extends Quest 
import outils 
import po3_SKSEFunctions

Actor Property PlayerRef Auto  
ODefeatMCM Property ODefMCM Auto
OsexIntegrationMain Property Ostim Auto

ObjectReference[] property droppedItems auto
faction property calmFaction auto
Package Property DoNothing Auto
Sound property FXMeleePunchLargeS auto
 
Sound property FXMeleePunchMediumS auto 

Spell property ODefeatSpell auto 
MagicEffect property ODefeatMagicEffect auto

ObjectReference Property posref Auto

bool Property EnablePlayerVictim
    bool Function Get()
        return (GetNthAlias(0) as ODefeatPlayer).EnableVictim
    EndFunction

    Function Set(bool Variable) ; todo mcm
        if variable 
            PlayerRef.StartDeferredKill()
            (GetNthAlias(0) as ODefeatPlayer).EnableVictim = true
        else 
            PlayerRef.SetActorValue("health", 25.0)
            PlayerRef.EndDeferredKill()
            (GetNthAlias(0) as ODefeatPlayer).EnableVictim = false
        endif 
    EndFunction
EndProperty

bool bResetPosAfterEnd

actor[] calmed

int stripStage
Float attackStatus
bool attackComplete
bool attackRunning
Osexbar defeatBar

Actor AttackingActor
Actor VictimActor

int nextInputNeeded 
int GameCompletionsSinceLastCheck

bool PlayerAttacker

bool OCrimeIntegration

int warmupTime

bool Property cheatMode = true auto ;TODO - disable for release

int startAttackKeyCode = 34 ;g ; todo mcm
int minigame0KeyCode = 42 ;leftshift ; todo mcm
int minigame1KeyCode = 54 ;rightshift ; todo mcm
int endAttackKeyCode = 57 ;spacebar ; todo mcm

actor[] savedFollowers

int property DefeatedAssaultChance auto ; todo mcm

; todo fix freecam on player victim
; bug - player cannot draw weapons after surviving victim scene (maybe after losing victim scene too?)


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

ODefeatMain Function GetODefeat() Global
    return outils.GetFormFromFile(0x12c5, "odefeat.esp")  as ODefeatMain
endfunction

Function KillPlayer() Global
    actor player = game.GetPlayer()

    ;debug.SendAnimationEvent(Player, "IdleForceDefaultState")
    player.EndDeferredKill()
    player.KillEssential()
endfunction 

Function startup()


    ; Attack status information.
    attackStatus = 0 
    attackComplete = False ; Attack has finshed completely.
    attackRunning = False ; Attack is in progress.

    EnablePlayerVictim = true

    DefeatedAssaultChance = 100 ; todo mcm

    defeatBar = (Self as Quest) as Osexbar
    
    OCrimeIntegration = OUtils.IsModLoaded("ocrime.esp")

    droppedItems = PapyrusUtil.ObjRefArray(6, none)

    posref = playerref.PlaceAtMe((Quest.GetQuest("0SA") as _oOmni).OBlankStatic) as ObjectReference

    InitBar(defeatBar)
    OUtils.RegisterForOUpdate(self)
    ostim.RegisterForGameLoadEvent(self)

    OnGameLoad()

    Debug.notification("ODefeat installed")
EndFunction

Event OnGameLoad()
    RegisterForModEvent("ostim_end", "OstimEnd")
    RegisterForModEvent("ostim_totalend", "OstimTotalEnd")
    attackRunning = false

     ; Register for keypress events. I'm not sure what all of these do yet.
    RegisterForKey(startAttackKeyCode) ;G - attacks
    RegisterForKey(minigame0KeyCode) ;leftshift - Minigame key 1
    RegisterForKey(minigame1KeyCode) ;rightshift - Minigame key 2
    RegisterForKey(endAttackKeyCode) ;Space - exit minigame fast
EndEvent

Event onKeyDown(int keyCode)
    
    if MenuOpen()
        return
    endif

    if attackRunning
        

        if keyCode == minigame0KeyCode && nextInputNeeded == 0
            nextInputNeeded = 1

        elseif keyCode == minigame1KeyCode && nextInputNeeded == 1
            nextInputNeeded = 0
            cycleDone()
        elseif keyCode == endAttackKeyCode
            GameCompletionsSinceLastCheck = -200
        endif
    Elseif (keyCode == startAttackKeyCode) ; G
        ;Try to perform attack, or strip dead npc?
        attackKeyHandler()
    EndIf
EndEvent

Function InitBar(OSexBar setupBar)
    setupBar.HAnchor = "left"
    setupBar.VAnchor = "bottom"
    setupBar.X = 495
    setupBar.Y = 600
    setupBar.Alpha = 0.0
    setupBar.FlashColor = 0x000000
    setupBar.SetPercent(50.0)
    ;setupBar.FillDirection = "center"
    ;setupBar.SetColors(0xFE1B61, 0xB0B0B0) 
    setupBar.SetColors(0xFF96e6, 0x9F1666)  

    setupbar.SetBarVisible(False)
endFunction



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
    stripStage ;?

    ; fire rape alert if ocrime installed
    if OCrimeIntegration
        int ocrime_event = ModEvent.Create("ocrime_crime")
        ModEvent.PushForm(ocrime_event, attacker)
        ModEvent.PushBool(ocrime_event, true)
        ModEvent.Send(ocrime_event)
    endif 


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
    GameCompletionsSinceLastCheck = 0
    bool victory
    nextInputNeeded = 0
    int difficultyCounter = 0
    int attackPower = 10

    defeatbar.SetBarVisible( true)

    RunStruggleAnim(attacker, victim) 
    
    while (!attackComplete)
        if (warmupTime > 0) ; A little bit of time at the begining for getting ready.
            if (GameCompletionsSinceLastCheck > 0)
                warmupTime = 0
            else
                warmupTime -= 1
            endif
        else ; do the main minigame loop.           

            
            if (PlayerAttacker)
                attackStatus += (GameCompletionsSinceLastCheck * attackPower) - difficulty
            else
                attackStatus -= (GameCompletionsSinceLastCheck * attackPower) - difficulty
            endif

            defeatBar.SetPercent(attackStatus / 100.0)
            GameCompletionsSinceLastCheck = 0

            if(!cheatMode)
                difficultyCounter += 1
                if difficultyCounter >= 50 ;boost difficulty if slow (5 seconds)
                    difficulty += 1
                    difficultyCounter = 0
                endif
            endif
            
            if (attackStatus > GetNextAttackStatusStripThreshold())
                stripItem(Victim, GetNextStripItem(Victim))
                GoToNextState()
            endif

            if (attackStatus <= 0) ; If attackStatus bar is empty, exit loop.
                attackComplete = True
                victory = false
            elseif (attackStatus >= 100) ; If attackStatus bar is full, exit loop.
                attackComplete = True
                victory = True
            endIf
        endIf
        Utility.Wait(0.1)
    endWhile

    defeatbar.SetBarVisible(false)
    
    ; On Struggle End
    if (Victory) ; the attacker won
        runStruggleAnim(attacker, victim, false, (attacker == PlayerRef))
        attacker.SetDontMove(true)
        if (PlayerAttacker) ; player won against an npc
            doTrauma(victim)
        else ; player is Defeated
            PlayerDefenseFailedEvent(attacker)
        endif
        attacker.SetDontMove(false)
    else ; victim won
        Console("victim won")
        runStruggleAnim(attacker, victim, false, false, true)
        if PlayerAttacker
            Attacker.PushActorAway(victim, 0) ;seems to fail on some actors?
        else 
            debug.SendAnimationEvent(victim, "IdleForceDefaultState")
        endif 
        Victim.PushActorAway(Attacker, 3)

        FXMeleePunchLargeS.Play(Attacker)
        if (PlayerAttacker) ; player failed to get an npc
            Game.triggerscreenblood(20)
            victim.StartCombat(attacker)
			victim.DrawWeapon()
        else ; player escaped alive
            playerref.RestoreActorValue("health", playerref.GetActorValueMax("health") / 2.0)
            PlayerRef.SetDontMove(false)
            attacker.StartCombat(attacker)
			attacker.DrawWeapon()
            ToggleCombat()
        endif
    endif



    attackRunning = false
EndFunction

Function cycleDone() 
    GameCompletionsSinceLastCheck += 1
    if chanceRoll(33)
        Game.ShakeCamera(PlayerRef, afStrength = 1, afDuration = 0.3)

        
            actor damaged
            int damage

            if chanceRoll(66) ;Damage either the atacking actor or victim
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

        MoveToNearestNavmeshLocation(posref)

		float[] CenterLocation = new float[6] ; Get coords of posref exactly.

        float[] temp = OSANative.GetCoords(posref)
		CenterLocation[0] = temp[0]
		CenterLocation[1] = temp[1]
		CenterLocation[2] = temp[2]
		CenterLocation[3] = 21
		CenterLocation[4] = 0
		CenterLocation[5] = 240

        if (Attacker == PlayerRef) ; place and align attacker
  

         

            int offset = osanative.RandomInt(20, 30)
            OSANative.SetPositionex( playerref, CenterLocation[0], CenterLocation[1] - 15, CenterLocation[2] + 6)
            Attacker.SetAngle(CenterLocation[3] - 60, CenterLocation[4], CenterLocation[5] - offset)

            ConsoleUtil.ExecuteCommand("player.setangle x 10") ; first person camera allignment

             
        else
            Attacker.SetPosition(CenterLocation[0] + 5, CenterLocation[1] + 10, CenterLocation[2] + 6)
            Attacker.SetAngle(CenterLocation[3], CenterLocation[4], CenterLocation[5])
        endif

        ; Place and align victim.
        victim.SetAngle(CenterLocation[3], CenterLocation[4], CenterLocation[5])
        if (victim == PlayerRef)
            OSANative.SetPositionEx(victim, CenterLocation[0], CenterLocation[1], CenterLocation[2] + 5)
        else 
            victim.SetPosition(CenterLocation[0], CenterLocation[1], CenterLocation[2] + 5)
        endif 
       

        ; disable collision
        ostim.DisableCollision(victim)
        ostim.DisableCollision(attacker)

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
        ostim.EnableCollision(victim)
        ostim.EnableCollision(attacker)

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

Function MoveToSafeSpot()
    Game.FadeOutGame(False, True, 25.0, 25.0)
    SetUIVisible(false)
    SetSkyUIWidgetsVisible(false)


    cell currCell = playerref.GetParentCell()

    if currCell.isinterior()
        location currLocation = playerref.GetCurrentLocation()
        ObjectReference marker = OSANative.GetLocationMarker(currLocation)

       ; Console(currLocation.GetName())
       ; console(marker)

        bool exit = false
        while (marker.IsInInterior() || marker == none) && !exit
            currLocation = GetParentLocation(currLocation)
            if currLocation
                Console(currLocation.GetName())
                marker = OSANative.GetLocationMarker(currLocation)
            else 
                Console("Warning: no safe location found")
                exit = true
            endif 
        endwhile 

        if marker 
            PlayerRef.moveto(marker)
            Game.FadeOutGame(False, True, 25.0, 25.0)
        endif 
    endif  
    
    cell[] cells = GetAttachedCells()

    cell TargetCell

    int i = 0
    int l = cells.Length
    while i < l 
        location loc = CellToLocation(cells[i])

       ; Console(loc)

        if loc == none 
            TargetCell = cells[i]
            l = cells.Length
        endif 
         
        i += 1
    endwhile

    if !TargetCell
        targetcell = cells[osanative.randomint(0, cells.Length - 1)]
    endif 

    playerref.MoveTo(TargetCell.GetNthRef(0))
    Game.FadeOutGame(False, True, 25.0, 25.0)


    MoveToNearestNavmeshLocation(PlayerRef)
    Game.FadeOutGame(False, True, 25.0, 25.0)

    if savedFollowers.Length > 0
        i = 0 
        while i < savedFollowers.Length
            savedFollowers[i].MoveTo(PlayerRef, OSANative.RandomFloat(-512, 512), OSANative.RandomFloat(-512, 512), abMatchRotation = false)
            MoveToNearestNavmeshLocation(savedFollowers[i])

            savedFollowers[i].PushActorAway(savedFollowers[i], 0.1)
            i += 1
        EndWhile
    endif 

    if isinfirstperson()

        game.ForceFirstPerson()
       ; Console("in first person")
        debug.SendAnimationEvent(playerref, "TG05_GetUp")
    else 
        ;Console("not in first person")
        PlayerRef.PushActorAway(playerref, 0.1)
    endif 

    ostim.FadeFromBlack(6.0)
    Utility.Wait(6.5)

    SetUIVisible(true)
    SetSkyUIWidgetsVisible(true)

    debug.Notification("You were dumped nearby")
EndFunction

location Function CellToLocation(cell c)
    return c.GetNthRef(0).GetCurrentLocation()
EndFunction

Function PlayerDefenseFailedEvent(actor aggressor) 
    bool bUseFades = ostim.UseFades
    ostim.UseFades = false
    bool bAutoFades = ostim.UseAutoFades
    ostim.UseAutoFades = false
    ostim.FadeToBlack()

    startscene(aggressor, playerref)

    actor[] followers = papyrusutil.removeactor(GetCombatAllies(playerref), PlayerRef)
   

    if followers.Length > 0
        console("Player has followers")

        actor[] allNearbyEnemies = GetCombatTargets(PlayerRef)

        ;remove player and followers 
        allNearbyEnemies = PapyrusUtil.RemoveActor(allNearbyEnemies, aggressor)
        allNearbyEnemies = ShuffleActorArray(allNearbyEnemies)


        int i = 0
        int l = followers.Length
        while (i < l) 
            bool found = false 

            if followers[i].GetDistance(PlayerRef) < 256
                float sign
                if ChanceRoll(50)
                    sign = -1.0
                else 
                    sign = 1.0
                endif 

                followers[i].MoveTo(PlayerRef, afXOffset = (OSANative.RandomFloat(256.0, 1024.0) * sign), afYOffset = (OSANative.RandomFloat(256.0, 1024.0) * sign), abmatchrotation = false)
                MoveToNearestNavmeshLocation(followers[i])
            endif 

            RandomizeAngle(followers[i])

            int j = 0
            int l2 = allNearbyEnemies.Length
            while j < l2 
                actor char = allNearbyEnemies[j]
                if isValidAttackTarget(char)
                    j = l2 
                    found = true
                    allNearbyEnemies = PapyrusUtil.RemoveActor(allNearbyEnemies, char)

                    char.moveto(followers[i])
                    StartScene(char, followers[i])
                    Console("Partner found : " + char.GetDisplayName())
                endif 

                j += 1
            endwhile

            if !found 
                Console("No partner found")
                dotrauma(followers[i])
            endif 

            i += 1
        EndWhile 
    else 
        console("Player has no followers")
    endif 

    ostim.FadeFromBlack()

    Utility.Wait(3)
    ostim.UseFades = bUseFades
    ostim.UseAutoFades = bAutoFades
endFunction

actor[] function GetNearbyActors()
    return GetActorsByProcessingLevel(0)
endfunction

Function StartScene(actor Dom, actor Sub)
    ostim.AddSceneMetadata("odefeat")

    bool npcScene = false

    if dom == PlayerRef
        ostim.AddSceneMetadata("odefeat_aggressor")
    elseif sub == PlayerRef
        ostim.AddSceneMetadata("odefeat_victim")
        ostim.SkipEndingFadein = true
        PlayerRef.SetDontMove(false)
        savedFollowers = GetCombatAllies(PlayerRef)
        savedFollowers = PapyrusUtil.RemoveActor(savedFollowers, PlayerRef)
        MassCalm(GetCombatTargets(playerref))
        bResetPosAfterEnd = ostim.ResetPosAfterSceneEnd
        ostim.ResetPosAfterSceneEnd = false 
    else 
        npcscene = true
    endif 

    if !npcScene
        Ostim.StartScene(dom, sub, Aggressive = True, AggressingActor = dom)
    else 
        ostim.GetUnusedSubthread().StartScene(dom, sub, isaggressive = true, aggressingActor = dom, LinkToMain = true)
    endif 
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
        Target.EvaluatePackage() ; Why do we do this? We aren't applying any new packages. ; no idea

        RandomizeAngle(target) ;randomize laying pos.

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

Function RandomizeAngle(actor target)
    target.SetAngle(target.GetAngleX(), target.GetAngleY(), OSANative.RandomFloat(0.0, 359.9)) 
endfunction

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

Event MassCalm(actor[] acts)
    calmed = acts 

    int i = 0
    int l = calmed.Length
    while i < l 
        docalm(calmed[i], dontMove = false, enter = true)

        i += 1
    endwhile
EndEvent

Event UndoMassCalm()
    int i = 0
    int l = calmed.Length
    while i < l 
        docalm(calmed[i], dontMove = false, enter = false)

        i += 1
    endwhile
EndEvent

Bool Function isValidAttackTarget(actor target)
    ; Returns if actor is valid attack target.
    If (!outils.IsChild(target))
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
            droppedItem.applyHavokImpulse(osanative.RandomFloat(-2.0, 2.0), osanative.RandomFloat(-2.0, 2.0), osanative.RandomFloat(0.2, 1.8), osanative.RandomFloat(10, 50))
        endif
        droppedItems[stripStage] = DroppedItem
    endif
    stripStage += 1
endFunction


Float Function getActorAttackDifficulty(actor target)
    ; Return a float of the Difficulty of the attack minigame, based off the actor pased in.    
    ; Dificulty is clamped between 10 and 5 
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
    if ostim.HasSceneMetadata("odefeat_aggressor")
        doTrauma(ostim.getsexpartner(ostim.GetAggressiveActor()), enter = true)
    endif
EndEvent 

Event OStimTotalEnd(string eventName, string strArg, float numArg, Form sender)
    if ostim.HasSceneMetadata("odefeat_victim")
        Utility.Wait(2)

        MoveToSafeSpot()

        toggleCombat() ; todo, better

        OSANative.SendEvent(self, "UndoMassCalm")

        ostim.SkipEndingFadein = false

        ostim.ResetPosAfterSceneEnd = bResetPosAfterEnd
    endif 
EndEvent


; This just makes life easier sometimes.
Function WriteLog(String OutputLog, bool error = false)
    MiscUtil.PrintConsole("ODefeat: " + OutputLog)
    Debug.Trace("ODefeat: " + OutputLog)
    if (error == true)
        Debug.Notification("ODefeat: " + OutputLog)
    endIF
EndFunction









;; Base State
function GotoNextState()    
    GotoState("StrippedHelmet")
endFunction

form function GetNextStripItem(actor target)
    return target.GetWornForm(0x00000002) ; Helmet
endFunction

float function GetNextAttackStatusStripThreshold()
    if(playerattacker)
            return 20
        else
            return 84
        endif
endfunction
;;

state StrippedHelmet
    form function GetNextStripItem(actor target)
        return target.GetWornForm(0x00000008) ; Gauntlets
    endFunction

    float function GetNextAttackStatusStripThreshold()
        if(playerattacker)
                return 40
            else
                return 87
            endif
    endfunction

    function GotoNextState()
        GotoState("StrippedGauntlets")
    endFunction
endState

state StrippedGauntlets
    form function GetNextStripItem(actor target)
        return target.GetWornForm(0x00000080) ; feet
    endFunction

    float function GetNextAttackStatusStripThreshold()
        if(playerattacker)
                return 60
            else
                return 91
            endif
    endfunction
    
    function GotoNextState()
        GotoState("StrippedFeet")
    endFunction
endState

state StrippedFeet
    form function GetNextStripItem(actor target)
        return target.GetEquippedObject(0) as form ; left hand
    endFunction

    float function GetNextAttackStatusStripThreshold()
        if(playerattacker)
                return 80
            else
                return 94
            endif
    endfunction

    function GotoNextState()
        GotoState("StrippedLeftHand")
    endFunction
endState

state StrippedLeftHand
    form function GetNextStripItem(actor target)
        return target.GetEquippedObject(1) as form ; right hand
    endFunction

    float function GetNextAttackStatusStripThreshold()
        if(playerattacker)
                return 90
            else
                return 96
            endif
    endfunction

    function GotoNextState()
        GotoState("StrippedRightHand")
    endFunction
endState

state StrippedRightHand
    form function GetNextStripItem(actor target)
        return target.GetWornForm(0x00000004) ; armor
    endFunction

    float function GetNextAttackStatusStripThreshold()
        if(playerattacker)
                return 95
            else
                return 98
            endif
    endfunction

    function GotoNextState()
        GotoState("StrippedArmor")
    endFunction
endState

state StrippedArmor
    form function GetNextStripItem(actor target)
    endFunction

    float function GetNextAttackStatusStripThreshold()
        return 200
    endfunction

    function GotoNextState()
    endFunction
endState
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



int property oDefeatEventsJDB
    int function get()
        return JDB.solveObj(".ODefeat.events")
      endfunction
      function set(int object)
        JDB.solveObjSetter(".ODefeat.events", object, true)
      endfunction
endproperty

bool Property EnablePlayerVictim
    bool Function Get()
        return (GetNthAlias(0) as ODefeatPlayer).EnableVictim
    EndFunction

    Function Set(bool Variable)
        if variable 
            PlayerRef.StartDeferredKill()
            (GetNthAlias(0) as ODefeatPlayer).EnableVictim = true
        else 
            if EnablePlayerVictim
                Debug.MessageBox("Disabling this requires a new game.")
            else    
                (GetNthAlias(0) as ODefeatPlayer).EnableVictim = false
            endif 
        endif 
    EndFunction
EndProperty

bool Property EnablePlayerAggressor auto


bool property MaleNPCsWontAssault auto
bool property FemaleNPCsWontAssault auto

int Property MinValueToRob Auto

bool bResetPosAfterEnd

float property MinigameDifficultyModifier auto

int stripStage
Float attackStatus
bool GameComplete
bool attackRunning
Osexbar defeatBar

int property RobberyItemStealChance auto

Actor property AttackingActor auto
Actor property VictimActor auto

int nextInputNeeded 
int GameCompletionsSinceLastCheck

bool PlayerAttacker

bool OCrimeIntegration

int warmupTime

bool Property cheatMode = false auto 

int property startAttackKeyCode auto
int property minigame0KeyCode auto
int property minigame1KeyCode auto
int property endAttackKeyCode auto

int property DefeatedAssaultChance auto
int property DefeatedSkipChance auto
int property MoralityToAssault auto
int property DefeatSexChance auto ;mcm todo
bool property FollowersGetAssaulted auto



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
    return outils.GetFormFromFile(0x801, "odefeat.esp")  as ODefeatMain
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
    GameComplete = true ; Attack has finshed completely.
    attackRunning = False ; Attack is in progress.


    defeatBar = (Self as Quest) as Osexbar

    OCrimeIntegration = OUtils.IsModLoaded("ocrime.esp")

    droppedItems = PapyrusUtil.ObjRefArray(6, none)

    InitBar(defeatBar)
    OUtils.RegisterForOUpdate(self)
    ostim.RegisterForGameLoadEvent(self)

    ;CustomScenes[1] = Game.GetFormFromFile(0x00000800, "odeftest.esp")
    ;sceneWeights[1] = 100

    registerforkey(26)
    registerforkey(27)

    perk RobPerk = GetFormFromFile(0x807, "oDefeat.esp") as perk 
    PlayerRef.RemovePerk(RobPerk)
    PlayerRef.AddPerk(robperk)

    if ostim.GetAPIVersion() < 23 
        debug.MessageBox("Your OStim version is out of date. ODefeat requires a newer version")
        return 

    endif 

    if (CanActorBeDetected(PlayerRef) == 0 )
        debug.MessageBox("po3's papyrus extender is out of date or not installed. please update")
        return
    endif 

    if !MiscUtil.FileExists("data/scripts/nl_mcm.pex")
        Debug.MessageBox("NL_MCM is not installed. Please install it to use ODefeat")
        return
    endif 



    SetDefaultSettings()

    OnGameLoad()

    Debug.notification("ODefeat installed")
EndFunction



Event OnGameLoad()
    if !OSANative.DetectionActive()
        Writelog("Enabling combat")
        EnableCombat(true)
    endif 
    RegisterForModEvent("ostim_end", "OstimEnd")
    RegisterForModEvent("ostim_totalend", "OstimTotalEnd")
    attackRunning = false
    
    RegisterForKey(startAttackKeyCode) ;G - attacks
    RegisterForKey(minigame0KeyCode) ;leftshift - Minigame key 1
    RegisterForKey(minigame1KeyCode) ;rightshift - Minigame key 2
    RegisterForKey(endAttackKeyCode) ;Space - exit minigame fast

    ; Native Defeat Events:
    RegisterForModEvent("oDefeat_robberyEvent", "robberyEvent")
    RegisterForModEvent("oDefeat_safeWakeupEvent", "safeWakeupEvent")
    RegisterForModEvent("oDefeat_killEvent", "killEvent")

EndEvent

Function SetDefaultSettings()
    if !EnablePlayerVictim
        EnablePlayerVictim = false
    endif 
    EnablePlayerAggressor = true

    MaleNPCsWontAssault = false 
    FemaleNPCsWontAssault = true 

    MinValueToRob = 350

    startAttackKeyCode = 34 ;g
    minigame0KeyCode = 42 ;leftshift
    minigame1KeyCode = 54 ;rightshift
    endAttackKeyCode = 57 ;spacebar

    DefeatedAssaultChance = 100
    DefeatedSkipChance = 0
    MoralityToAssault = 1
    FollowersGetAssaulted = true

    DefeatSexChance = 100
    RobberyItemStealChance = 50
    MinigameDifficultyModifier = 0.0
endfunction 

Event onKeyDown(int keyCode)
    if MenuOpen()
        return
    endif

    if !GameComplete 
        if keyCode == minigame0KeyCode && nextInputNeeded == 0
            nextInputNeeded = 1
        elseif keyCode == minigame1KeyCode && nextInputNeeded == 1
            nextInputNeeded = 0
            cycleDone()
        elseif keyCode == endAttackKeyCode
            GameCompletionsSinceLastCheck = -200
        endif
    Elseif (EnablePlayerAggressor && keyCode == startAttackKeyCode)
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

    weaponWasDrawn = PlayerRef.IsWeaponDrawn()


    attacker.SheatheWeapon()
    victim.SheatheWeapon()
    float difficulty

    ; fire rape alert if ocrime installed
    if OCrimeIntegration && (!(victim.GetCrimeFaction() == none) || (victim == PlayerRef))
        int ocrime_event = ModEvent.Create("ocrime_crime")
        ModEvent.PushForm(ocrime_event, attacker)
        ModEvent.PushBool(ocrime_event, true)
        ModEvent.Send(ocrime_event)
    endif 

    ;Setup Bar percents
    if (PlayerAttacker)
        difficulty = getActorAttackDifficulty(victim)
        defeatBar.setPercent(0.05)
        AttackStatus = 5.0
    Else
        difficulty = getActorAttackDifficulty(attacker)
        defeatBar.setPercent(0.80)
        AttackStatus = 80.0
        PlayerRef.SetDontMove(True)
        
        OSANative.SendEvent(self, "FastDisableCombat")
    EndIf

    bool victory = minigame(difficulty)

    ; On Struggle End
    if (Victory) ; the attacker won
        
        if (PlayerAttacker) ; player won against an npc
            runStruggleAnim(attacker, victim, false, true)

            attacker.DrawWeapon()

            doTrauma(victim)

            RestorePlayerState()
            UnregisterForAnimationEvent(PlayerRef, "GetUpEnd")
            if !tNPCVictory && ostim.ShowTutorials
                tNPCVictory = true 

                ostim.DisplayToastAsync("You defeated the NPC", 2.5)
                ostim.DisplayToastAsync("Press " + GetButtontag(startAttackKeyCode) + " on them while they are down to start an OStim scene", 7.0)
            endif 
        else ; player is Defeated
            attacker.SetDontMove(true)

            PlayerDefenseFailedEvent(attacker)

            UnregisterForAnimationEvent(PlayerRef, "GetUpEnd")
        endif
        attacker.SetDontMove(false)
    else ; victim won
        Writelog("victim won")
        runStruggleAnim(attacker, victim, false, false, true)
        if PlayerAttacker
            Attacker.PushActorAway(victim, 0) ;seems to fail on some actors?
        
        endif 
        Victim.PushActorAway(Attacker, 3)

        FXMeleePunchLargeS.Play(Attacker)
        if (PlayerAttacker) ; player failed to get an npc
            Game.triggerscreenblood(20)
            victim.StartCombat(attacker)
			victim.DrawWeapon()

            if !tNPCFail && ostim.ShowTutorials
                tNPCFail = true
                Utility.Wait(6.0)
                ostim.DisplayToastAsync("Lower your enemy's health for better odds", 5.0)
                ostim.DisplayToastAsync("Press " + GetButtontag(endAttackKeyCode) + " to give up early during a struggle", 3.0)

            endif 
        else ; player escaped alive
            playerref.RestoreActorValue("health", (playerref.GetBaseActorValue("health") / 2.0) +  (math.abs( PlayerRef.GetActorValue("health") )))
            PlayerRef.SetDontMove(false)
            struggleActorPreventMove(PlayerRef, false)
            attacker.StartCombat(attacker)
			attacker.DrawWeapon()

            RestorePlayerState()
            UnregisterForAnimationEvent(PlayerRef, "GetUpEnd")

            EnableCombat(true, forceReengage = true)
        endif
    endif


    attackRunning = false
EndFunction

bool tNPCFail
bool tNPCVictory
bool tMinigame
bool Function Minigame(float difficulty, bool strip = true, bool struggle = true)
    if !tminigame && ostim.showtutorials
        tminigame = true 

        ostim.DisplayToastAsync("Alternate between pressing " + GetButtontag(minigame0KeyCode) + " and " + GetButtontag(minigame1KeyCode) + " rapidly", 6.0)
    endif 
    if struggle
        RunStruggleAnim(AttackingActor, VictimActor) 
    endif 


    GameCompletionsSinceLastCheck = 0
    nextInputNeeded = 0
    int attackPower = 10
    int difficultyCounter
    GameComplete = False
    droppedItems = PapyrusUtil.ObjRefArray(6, none) ; reset clothes cache
    warmupTime = 20


    bool victory

    defeatbar.SetBarVisible( true)

    while (!GameComplete)
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

            GameCompletionsSinceLastCheck = 0
            defeatBar.SetPercent(attackStatus / 100.0)

            if(!cheatMode)
                difficultyCounter += 1
                if difficultyCounter >= 50 ;boost difficulty if slow (5 seconds)
                    difficulty += 1
                    difficultyCounter = 0
                endif
            endif
            
            if strip
                if (attackStatus > GetNextAttackStatusStripThreshold()) && (VictimActor != PlayerRef)
                    stripItem(VictimActor, GetNextStripItem(VictimActor))
                    GoToNextState()
                endif
            endif

            if (attackStatus <= 0) ; If attackStatus bar is empty, exit loop.
                GameComplete = True
                victory = false
            elseif (attackStatus >= 100) ; If attackStatus bar is full, exit loop.
                GameComplete = True
                victory = True
            endIf
        endIf
        Utility.Wait(0.1)
    endWhile

    defeatbar.SetBarVisible(false)

    return victory
endfunction

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

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
    
    if asEventName == "GetUpEnd"
        RestorePlayerState()

        UnregisterForAnimationEvent(PlayerRef, "GetUpEnd")
    endif 
EndEvent

Function RestorePlayerState()
    if wasInFirstPerson
       game.ForceFirstPerson()
    endif 
    if weaponWasDrawn
        PlayerRef.DrawWeapon()
    endif 
EndFunction

bool wasInFirstPerson
bool weaponWasDrawn
Function runStruggleAnim(Actor attacker, actor victim, bool animate = true, bool victimStayDown = false, bool noIdle = false)
    ; Run struggle animation.
    if (animate)
        wasInFirstPerson = IsInFirstPerson()



        struggleActorPreventMove(attacker, true)
        struggleActorPreventMove(victim, true)

        RegisterForAnimationEvent(PlayerRef, "GetUpEnd")

        if !posref
            Writelog("Posref not found, making new one")
            posref = GetBlankObject()
        endif 
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
		CenterLocation[2] = temp[2] + 5 
		CenterLocation[3] = 21
		CenterLocation[4] = 0
		CenterLocation[5] = 240

        float terrainMagnetOffset = 0.0
        float terrainMagnetOffsetHeight = 0.0

        if GetObjectUnderFeet(PlayerRef) == none 
            Writelog("odefeat alignment warning")
            Writelog(GetObjectUnderFeet(PlayerRef))

            CenterLocation[2] = CenterLocation[2] + 33
        else 
            if victim == PlayerRef
                terrainMagnetOffset = 5.0
                terrainMagnetOffsetHeight = -5.0
            endif
        endif 

        if (Attacker == PlayerRef) ; place and align attacker
  

         
                        


            int offset = osanative.RandomInt(20, 30)
            attacker.SetPosition(CenterLocation[0], CenterLocation[1] - 15, CenterLocation[2] )
            Attacker.SetAngle(CenterLocation[3] - 60, CenterLocation[4], CenterLocation[5] - offset)

            ConsoleUtil.ExecuteCommand("player.setangle x 10") ; first person camera allignment


             
        else
            Attacker.SetPosition(CenterLocation[0] + 5 + terrainMagnetOffset, CenterLocation[1] + 10, CenterLocation[2])
            Attacker.SetAngle(CenterLocation[3], CenterLocation[4], CenterLocation[5])
        endif

        ; Place and align victim.
        victim.SetAngle(CenterLocation[3], CenterLocation[4], CenterLocation[5])
        victim.SetPosition(CenterLocation[0], CenterLocation[1], CenterLocation[2] + terrainMagnetOffsetHeight)
       

 

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
            act.SetDontMove(true)
        else
            ActorUtil.AddPackageOverride(act, DoNothing, 100, 1)
            act.EvaluatePackage()
            act.SetRestrained(true)
            act.SetDontMove(true)
        endif


    else
        if (act == PlayerRef)
            Game.SetPlayerAiDriven(False)
            act.SetDontMove(false)
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

       ; Writelog(currLocation.GetName())
       ; Writelog(marker)

        bool exit = false
        while (marker.IsInInterior() || marker == none) && !exit
            currLocation = GetParentLocation(currLocation)
            if currLocation
                Writelog(currLocation.GetName())
                marker = OSANative.GetLocationMarker(currLocation)
            else 
                Writelog("Warning: no safe location found")
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

       ; Writelog(loc)

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

    if lastKnownAllies.Length > 0
        i = 0 
        while i < lastKnownAllies.Length
            lastKnownAllies[i].MoveTo(PlayerRef, OSANative.RandomFloat(-512, 512), OSANative.RandomFloat(-512, 512), abMatchRotation = false)
            MoveToNearestNavmeshLocation(lastKnownAllies[i])

            lastKnownAllies[i].PushActorAway(lastKnownAllies[i], 0.1)
            i += 1
        EndWhile
    endif 

    if isinfirstperson()

        game.ForceFirstPerson()
        Writelog("in first person")
        debug.SendAnimationEvent(playerref, "TG05_GetUp")
    else 
        Writelog("not in first person")
        PlayerRef.PushActorAway(playerref, 0.1)
    endif 

    ostim.FadeFromBlack(6.0)
    Utility.Wait(6.5)

    SetUIVisible(true)
    SetSkyUIWidgetsVisible(true)

    debug.Notification("You were dumped nearby")
    if wasRobbed
        wasRobbed = false 

        debug.notification("You were robbed of your valuables")
    endif 
EndFunction

location Function CellToLocation(cell c)
    return c.GetNthRef(0).GetCurrentLocation()
EndFunction

bool tEscape

Function PlayerDefenseFailedEvent(actor aggressor) 
    runStruggleAnim(aggressor, PlayerRef, false, false)

    ostim.FadeToBlack()

    if !ChanceRoll(DefeatSexChance)
        PunishPlayer()
        return 
    endif 


    bool bUseFades = ostim.UseFades
    ostim.UseFades = false
    bool bAutoFades = ostim.UseAutoFades
    ostim.UseAutoFades = false
    


    startscene(aggressor, playerref)

    actor[] followers = lastKnownAllies
   

    if (FollowersGetAssaulted && followers.Length > 0)
        Writelog("Player has followers & follower assault enabled")

        actor[] allNearbyEnemies = lastKnownEnemies

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
                    Writelog("Partner found : " + char.GetDisplayName())
                endif 

                j += 1
            endwhile

            if !found 
                Writelog("No partner found")
                dotrauma(followers[i])
            endif 

            i += 1
        EndWhile 
    elseif (!FollowersGetAssaulted && followers.Length > 0)
        writelog("Player has followers & follower assault disabled")
        int i = 0
        int l = followers.Length
        while i < l
            dotrauma(followers[i])
            i += 1
        endwhile
    else 
        Writelog("Player has no followers")
    endif 

    Utility.Wait(0.5)
    while (!ostim.IsActorActive(PlayerRef)) && ostim.AnimationRunning()
        Utility.Wait(0.5)
    endwhile

    ostim.FadeFromBlack()

    if !tEscape && ostim.ShowTutorials
            tescape = true 
            SetUIVisible(true)
            Utility.Wait(2.5)
            DisplayToastText("Press " + GetButtontag(startAttackKeyCode) + " to attempt an escape", 3.0)
            DisplayToastText("Full stamina is required to attempt", 3.0)
            SetUIVisible(false)
    endif 

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

        PlayerRef.DamageActorValue("stamina", 999.0)

        bResetPosAfterEnd = ostim.ResetPosAfterSceneEnd
        ostim.ResetPosAfterSceneEnd = false 
        playerref.RestoreActorValue("health", 30 + (math.abs(PlayerRef.GetActorValue("health"))))
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
    if ostim.IsActorActive(playerref)
        if ostim.HasSceneMetadata("odefeat_victim")
            if PlayerRef.GetActorValuePercentage("stamina") > 0.98
                defeatBar.setPercent(0.90)
                AttackStatus = 90.0
                if !Minigame(getActorAttackDifficulty(ostim.GetAggressiveActor()), false, false)
                    ostim.AddSceneMetadata("odefeat_escaped")
                    ostim.EndAnimation(false)
                    ;PlayerRef.PushActorAway(ostim.GetAggressiveActor(), 5.0)
                    return
                else 
                    PlayerRef.DamageActorValue("stamina", 999.0)
                    return 
                endif 
            else 
                if !IsUIVisible()
                    SetUIVisible(true)
                    Utility.Wait(3)
                    SetUIVisible(false)
                endif 
                return
            endif 
        else 
            return 
        endif 
    endif 

    actor npc = Game.GetCurrentCrosshairRef() as Actor 

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

Function EnableCombat(bool enable, bool forceReengage = false)
    osanative.toggleCombat(enable)
    if enable 
        if forceReengage
            ResumeCombatAll()
            PlayerRef.CreateDetectionEvent(PlayerRef, 100)
        endif 
    else 
       StopCombatAll()
    endif 
EndFunction

Event FastDisableCombat()
    EnableCombat(false)
EndEvent

Function ResumeCombatAll() 
    int i = 0 
    int max = lastKnownEnemies.Length
    while i < max 
        lastKnownEnemies[i].StartCombat(PlayerRef)

        i += 1
    endwhile
endfunction 

Function StopCombatAll()
    lastKnownEnemies = GetCombatTargets(PlayerRef)
    lastKnownAllies = papyrusutil.removeactor(GetCombatAllies(PlayerRef), playerref)

    actor[] everyone = osanative.GetActors()
    int i = 0
    int max = everyone.Length
    while i < max 
        everyone[i].StopCombat()
        i += 1
    endwhile
endfunction

actor[] lastKnownEnemies 
actor[] lastKnownAllies

Bool Function doTrauma(Actor target, bool enter = true) ; credit: sexlab defeat - pretty much verbatim
    if (target.IsDead() || Target == PlayerRef)
        return false
    endif

    doCalm(target)

    if (Enter)
        Target.EvaluatePackage() ; Why do we do this? We aren't applying any new packages. ; no idea

        RandomizeAngle(target) ;randomize laying pos.

        Debug.SendAnimationEvent(Target, "IdleWounded_02")

        PreventActorDetection(target)
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
        ResetActorDetection(target)
        doCalm(Target, Enter = False)
        return true
    endif
    return false
EndFunction

Function RandomizeAngle(actor target)
    target.SetAngle(target.GetAngleX(), target.GetAngleY(), OSANative.RandomFloat(0.0, 359.9)) 
endfunction

Bool Function doCalm(Actor target, bool dontMove = true, bool enter = true)  ; credit: sexlab defeat - pretty much verbatim
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

bool wasRobbed
Function RobPlayer(actor robber)
    wasRobbed = true 
    form[] playerInv = AddAllItemsToArray(playerref,false, false, true)
    playerInv = osanative.RemoveFormsBelowValue(playerInv, MinValueToRob)

    int i = 0 
    int max = playerInv.Length
    while i < max 
        if ChanceRoll(RobberyItemStealChance)
            form thing = playerInv[i]

            PlayerRef.RemoveItem(thing, aiCount = PlayerRef.GetItemCount(thing), abSilent = true, akOtherContainer = robber)
        endif 

        i += 1
    endwhile 

EndFunction

Float Function getActorAttackDifficulty(actor target)
    ; Return a float of the Difficulty of the attack minigame, based off the actor pased in.    
    ; Dificulty is clamped between 10 and 4
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
    ret = PapyrusUtil.ClampFloat(ret, 4.0, 10.0)

    return ret + MinigameDifficultyModifier
endFunction

Event OStimEnd(string eventName, string strArg, float numArg, Form sender)
    if ostim.HasSceneMetadata("odefeat_escaped")  
        EnableCombat(true, true) 
        game.FadeOutGame(false, true, 0.0, 0.001)
   endif 
EndEvent 

Event OStimTotalEnd(string eventName, string strArg, float numArg, Form sender)
    if ostim.HasSceneMetadata("odefeat_victim") 
        if !ostim.HasSceneMetadata("odefeat_escaped") 
            PunishPlayer()
        endif 
        ostim.SkipEndingFadein = false
        ostim.ResetPosAfterSceneEnd = bResetPosAfterEnd
    endif 
EndEvent

Function PunishPlayer()
    Utility.Wait(2)
    DoCustomEvent()
    EnableCombat(true) 
EndFunction

function DoCustomEvent()
    string[] weightedArray = PapyrusUtil.StringArray(0)
    
    string eventkey = JMap.NextKey(oDefeatEventsJDB)
    while eventkey
        int tempint = JValue.SolveInt(oDefeatEventsJDB, "." + eventKey + ".Weighting")
        weightedArray = PapyrusUtil.MergeStringArray(weightedArray, papyrusUtil.StringArray(tempint, eventkey))
        eventkey = JMap.NextKey(oDefeatEventsJDB, eventkey)
    endwhile
    
    string chosenEvent = weightedArray[osanative.randomint(0, weightedArray.Length - 1)]
    string modEventName

    if (!chosenEvent) ; In case no valid death events are selected, falls back to safe wakeup.
        modEventName = "safeWakeupEvent"
        chosenEvent = "oDefeat Fallback Event"
        Writelog("No valid events enabled, fallback event triggered.", true)
    else
        modEventName = JValue.SolveStr(oDefeatEventsJDB, "."+chosenEvent+".modEventName")
    endif
    Writelog("Fired modevent: " + modEventName)
    SendModEvent(modEventName)
    CustomEvent_Notify(chosenEvent)
endFunction

Function CustomEvent_Notify(string eventName)
    int odefeat_CustomEvent = ModEvent.Create(odefeat_CustomEvent)
    if (odefeat_CustomEvent)
        ModEvent.PushString(odefeat_CustomEvent, eventName)
        ModEvent.Send(odefeat_CustomEvent)
    endif
endFunction

bool tRobbed

event robberyEvent(string eventName, string arg_s, float argNum, form sender)
    writelog(1)
    RobPlayer(ostim.GetAggressiveActor())
    MoveToSafeSpot()

    if !tRobbed && ostim.ShowTutorials
        Utility.Wait(3)
        tRobbed = true 

        ostim.DisplayToastAsync("You were robbed of some valuables", 3.5)
        ostim.DisplayToastAsync("Your items are in your attacker's inventory", 5.0)
    endif 
endEvent

event safeWakeupEvent(string eventName, string arg_s, float argNum, form sender)
    writelog(2)
    MoveToSafeSpot()
endEvent

event killEvent(string eventName, string arg_s, float argNum, form sender)
    writelog(3)
    KillPlayer()
endEvent

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

     return 20

endfunction
;;

state StrippedHelmet
    form function GetNextStripItem(actor target)
        return target.GetWornForm(0x00000008) ; Gauntlets
    endFunction

    float function GetNextAttackStatusStripThreshold()
  
                return 40
 
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
 
                return 60
 
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
 
        return 80
 
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
        return 90
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
 
        return 95

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

function getButtonName(int keycode)

endfunction
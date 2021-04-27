Scriptname SLGMainQuestScript extends Quest  
spell property succubusTraumaSpell auto
actor property playerref auto
Package Property DoNothing Auto
SexlabFramework Property SexLab Auto
Quest Property SuccubusQuest Auto


;---------------------Player SexualValue related-------------------
FavorJarlsMakeFriendsScript Property FavorJarlsMakeFriends Auto
Quest Property SlayedAlduin  Auto  
Quest Property wonCivilWar  Auto  
Faction Property SuccubusPrude Auto
AssociationType property Spouse Auto
AssociationType  property ParentChild auto
Faction Property SuccubusSeduced Auto
Faction Property JarlFaction auto
Faction Property CourtMageFaction auto
Faction Property StewardFaction auto

;crimefactions
Faction Property CrimeFactionEastmarch auto ;winterhold
Faction Property CrimeFactionFalkreath auto ;falkreath
Faction Property CrimeFactionHaafingar auto ;solitude
Faction Property CrimeFactionHjaalmarch auto ;morthal
Faction Property CrimeFactionOrcs auto ;orcs
Faction Property CrimeFactionPale auto ;dawnstar
Faction Property CrimeFactionReach auto ;markarth
Faction Property CrimeFactionRift auto ;riften
Faction Property CrimeFactionWhiterun auto ;whiterun
Faction Property CrimeFactionWinterhold auto ;riften

;-----------------------------------------------------------------

Topic property yes auto
Topic property No auto
Topic property Bribed auto
Topic property Hello Auto
Topic property Bye auto
Topic property HowMuch auto
faction property SuccubusDialogueFaction auto
MiscObject  Property Gold Auto
Sound property FXMeleePunchMediumS auto
Sound property FXMeleePunchLargeS auto
faction property calmFaction auto
Spell Property SuccCrimeSpell Auto
ReferenceAlias Property PlayerFollowerAlias auto
ReferenceAlias Property PlayerWaitAlias auto
ReferenceAlias Property SuccubusWalkAttacker auto
ReferenceAlias Property SuccubusWalkVictim auto
faction property SuccubusSlaveFaction auto
Quest Property SlaveQuest auto
FormList property SuccubusProcessedNPCs auto
SuccubusGameBar Bar
int cycleCount
bool runningAttack
int nextKey
int spellTimer
Float attackStatus
bool attackComplete
bool bountySet
int warmup
int difficultyCounter
bool victory
actor Aactor
actor property Dactor auto
actor PlayerFollowPartner
int stripStage
Armor[] clothes ; 0 head, 1 hands, 2 feet, 3 chest
ObjectReference[] property things auto
bool PlayerAttacker
bool property targetHasCrimeFaction auto
actor talker
float lastNudityReport
SuccubusApexScript apex
playersuccubustrackingscriptmale main
EFFCore eff
Quest Property FollowerExtension auto ; EFFCore script
int allowedVictimsMode
bool trackingNPCCombat
int npcCount
faction jobInnServer
faction FavorJobsBeggarFaction
faction succubusprocessed
faction MarkarthTempleofDibellaFaction
ObjectReference posref
String[] sexActs
Float[] sexPriceMults
bool playerOwesService
int lastAcceptedProstPrice
int lastSelectedAct
bool transPlayer ; true sex is kept secret
OsexIntegrationMain ostim
bool useOstimForNonAggressive

function Startup(SuccubusGameBar barinput)

	SuccubusProcessedNPCs = game.GetFormFromFile(0x254495, "DaedricSuccubus.esp") as FormList

	succubusprocessed = game.GetFormFromFile(0x1F9285, "DaedricSuccubus.esp") as faction

	ostim = game.GetFormFromFile(0x000801, "Ostim.esp") as OsexIntegrationMain

	useOstimForNonAggressive = true

	npcCount = 0
	Bar = barinput
	RegisterForKey(34) ;G
	RegisterForKey(42) ;leftshift
	RegisterForKey(54) ;rightshift
	RegisterForKey(57) ;space
	RegisterForKey(37) ;K

	RegisterForKey(207)  ; END

	Apex = SuccubusQuest as succubusapexscript
	main = SuccubusQuest as playersuccubustrackingscriptmale
	things = new ObjectReference[6]
	clothes = new Armor[4]
	eff = FollowerExtension as EFFCore

	posref = Game.GetFormFromFile(0x259599, "DaedricSuccubus.esp") As ObjectReference 

	jobInnServer = game.GetFormFromFile(0x0DEE93, "Skyrim.esm") as faction
	FavorJobsBeggarFaction = game.GetFormFromFile(0x060028, "Skyrim.esm") as faction
	MarkarthTempleofDibellaFaction = game.GetFormFromFile(0x0656EA, "Skyrim.esm") as faction

	;RegisterForSingleUpdate(2.0)

	attackStatus = 0
	attackComplete = false
	runningAttack = false
	cycleCount = 0
	trackingNPCCombat = false
	nextKey = 0 ;0 for left, 1 for right
	lastNudityReport = -1
	allowedVictimsMode = 1 ;1 = anyone, 2 = slaves only
	playerOwesService = false

		Bar.HAnchor = "left"
		Bar.VAnchor = "bottom"
		Bar.X = 495
		Bar.Y = 600
		Bar.Alpha = 0.0
		;Bar.FillDirection = "center"
		Bar.SetColors(0xFF96e6, 0x9F1666)
		Bar.FlashColor = 0x000000
		Bar.FadeTo(0, 0.5)
		Bar.SetPercent(0.0)

	sexActs = new String[5]
 	sexActs[0] = "vaginal"
 	sexActs[1] = "anal"
 	sexActs[2] = "oral"
 	sexActs[3] = "handjob"
 	sexActs[4] = "boobjob"

 	sexPriceMults = new float[5]
 	sexPriceMults[0] = 1.0
 	sexPriceMults[1] = 0.80
 	sexPriceMults[2] = 0.5
 	sexPriceMults[3] = 0.25
 	sexPriceMults[4] = 0.4

 	;Utility.wait(10)
 	;while !isTrans(playerref)
 	;	Utility.wait(1)
 	;EndWhile ;todo remove
 	;transPlayer = isTrans(playerref)
 	transPlayer = false
 	if transPlayer
 		debug.Notification("Marking player character as transgender")
 	endif

 	console("Appears female: " + appearsFemale(playerref))
 	console("is female: " + isFemale(playerref))
EndFunction

; When G is pressed, it will try to call AttemptAttack
Event onKeyDown(int keyn)
	

	if Utility.IsInMenuMode()
		Return
	EndIf

	if keyn == 34 ;G
		;debug.Notification("Attacking")
		;runningAttack = false
		;transPlayer = true
		if runningAttack
			Debug.Notification("Attack already running")
			Return
		endif

		objectreference ref = Game.GetCurrentCrosshairRef()
		;Debug.MessageBox(ref.GetBaseObject().GetType())
		if (ref as actor)	
			actor npc = ref as actor
			if !npc.IsDead()
				AttemptAttack(playerref, ref as actor)
			else
				StripNPC(npc)
			endif
		elseif (ref.GetBaseObject() as weapon) || (ref.GetBaseObject() as armor)
			
			playerref.AddItem(ref, abSilent = true)
			playerref.equipitem(ref.GetBaseObject())
		endif
	endif

	if keyn == 207
		openDataMenu()
	endif

	if keyn == 37 ;K


		;actor target = GetPlayerTalkPartner()
		actor target = Game.GetCurrentCrosshairRef() as actor

		if isEnslaved(target)
			openSlaveMenu(target)
		elseif ActorIsHelpless(target)
			opentraumamenu(target)
		elseif isFollower(target)
			openFollowerMenu(target)
		elseif target && !target.IsDead() && !target.IsInCombat() && !target.IsHostileToActor(playerref) && target.GetRace().HasKeyword(Keyword.GetKeyword("ActorTypeNPC"))
			if target == PlayerFollowPartner
				OpenSexStartMenu(target)
			Else
				OpenNPCMenu(target)
			endif
		endif
	endif

	if runningAttack
		if keyn == 42 && nextKey == 0
			nextKey = 1

		elseif keyn == 54 && nextKey == 1
			nextKey = 0
			cycleDone()
		elseif keyn == 57
			cycleCount = -200
		endif
	endif
endevent

Function AttemptAttack(actor attacker, actor victim)
	if !CanSex(victim)
		return
	endif
	if runningAttack
		Return
	endif
	runningAttack = true
	attacker.SheatheWeapon()
	victim.SheatheWeapon()
	targetHasCrimeFaction = victim.GetCrimeFaction() as Bool
	bountySet = false
	spellTimer = 30
	Aactor = attacker
	Dactor = victim

	if attacker == playerref
		PlayerAttacker = True
	Else
		PlayerAttacker = False
	endif

	stripStage = 0
	victory = false

	float difficulty = calcActordifficulty(victim)

	if PlayerAttacker
		difficulty = calcActordifficulty(victim)
		warmup = 20
		Bar.setpercent(0.05)
		AttackStatus = 5.0
	Else
		difficulty = calcActordifficulty(attacker) ;enemy, should be replaced with better algo but doesn't have to be
		warmup = 20
		Bar.setpercent(0.80)
		AttackStatus = 80.0
		playerref.SetDontMove(true) 
	;	Debug.SetGodMode(true)
		toggleCombat()

	endif

	Bar.FadeTo(100, 0.1)
	attackComplete = false
	
	difficultyCounter = 0

	bool violentAnim = true

	if 	ActorIsHelpless(victim) ;has trauma spell
		attackComplete = True
		victory = true
		;Just gonna start removing Player succ stuff.
		;if isEnslaved(victim)
		;	if playersuccubustrackingscriptmale.chanceRoll(75)
		;		violentAnim = false
		;	endif
		;endif
	Else
		StruggleAnim(victim, attacker) 
	endif
	
	SuccCrimeSpell.cast(Aactor)	;wtf?

	while !attackComplete
		if warmup > 0 ; free wait time to start
			if cycleCount > 0
				warmup = 0
			else
				warmup -= 1
			endif
		else
			if attackStatus <= 0 ;get out if bar empty or full
				attackComplete = true
				victory = false
			elseif attackStatus >= 100
				attackComplete = true
				victory = true
			endif

			if PlayerAttacker 
				attackStatus += cycleCount - difficulty ; cycle bar
			Else
				attackStatus -= cycleCount - difficulty
			endif

			Bar.setPercent(attackStatus / 100.0) 
			cycleCount = 0
			difficultyCounter += 1

			if difficultyCounter >= 50 ;boost difficulty if slow
				difficulty +=1
				difficultyCounter = 0
			endif


			if spellTimer < 1
				SuccCrimeSpell.cast(Aactor)		
				spellTimer = 30
			Else
				spellTimer -= 1
			endif


			if playerattacker
				if stripStage == 0 && attackStatus >= 20 ; helmet
					strip(victim.GetWornForm(0x00000002), victim)
				elseif stripStage == 1 && attackStatus >= 40 ;gauntlet
					strip(victim.GetWornForm(0x00000008), victim)
				elseif stripStage == 2 && attackStatus >= 60 ;feet
					strip(victim.GetWornForm(0x00000080), victim)
				elseif stripStage == 3 && attackStatus >= 80 ;left hand
					strip(victim.GetEquippedObject(0) as form, victim)
				elseif stripStage == 4  && attackStatus >= 90;right hand
					strip(victim.GetEquippedObject(1) as form, victim) 
				elseif stripStage == 5  && attackStatus >= 95 ;armor!
					strip(victim.GetWornForm(0x00000004), victim)
				endif
			else
				if stripStage == 0 && attackStatus >= 84 ; helmet
					strip(victim.GetWornForm(0x00000002), victim)
				elseif stripStage == 1 && attackStatus >= 87 ;gauntlet
					strip(victim.GetWornForm(0x00000008), victim)
				elseif stripStage == 2 && attackStatus >= 91 ;feet
					strip(victim.GetWornForm(0x00000080), victim)
				elseif stripStage == 3 && attackStatus >= 94 ;left hand
					strip(victim.GetEquippedObject(0) as form, victim)
				elseif stripStage == 4  && attackStatus >= 96;right hand
					strip(victim.GetEquippedObject(1) as form, victim) 
				elseif stripStage == 5  && attackStatus >= 98 ;armor!
					strip(victim.GetWornForm(0x00000004), victim)
				endif
			endif

		endif
			Utility.wait(0.1)
	endwhile
	
	;Debug.Messagebox(cycleCount)
	Bar.FadeTo(0, 0.5)
	runningAttack = false
	cycleCount = 0
	nextKey = 0

	if victory
		StruggleAnim(victim, attacker, false, true)
		
		

		if PlayerAttacker
			victim.SetDontMove(true)
		else
			attacker.SetDontMove(true)
		endif

		if PlayerAttacker
			
			if ActorIsHelpless(victim)
				doOStim(attacker, victim, -1, aggressive = true)
			else
				Trauma(victim)
			endif

		Else
			playerAttackFailedEvent(attacker)
			
		endif
		

		if PlayerAttacker
			victim.SetDontMove(False)
		else
			attacker.SetDontMove(false)
		endif

		;debug.Notification("sex over")
	else
		StruggleAnim(victim, attacker, false, false, True)
		attacker.pushactoraway(victim, 0)
		victim.pushactoraway(attacker, 3)
		FXMeleePunchLargeS.Play(Attacker)
		if PlayerAttacker
				Game.triggerscreenblood(20)
		endif

		if PlayerAttacker
			victim.StartCombat(attacker)
			victim.DrawWeapon()
		Else
			attacker.StartCombat(attacker)
			attacker.DrawWeapon()
		endif


	endif

	if !PlayerAttacker
		playerref.SetDontMove(false)
		Utility.wait(2)
		toggleCombat()
		;Debug.SetGodMode(false)
		;Game.DisablePlayerControls(false, false, false, false, false, false, false)
	endif
endfunction

Float Function calcActorDifficulty(actor target) ; 5 easy. 7 hard.
 
	;/-----------------DATA------------
		dungeon data

		player level 1
		Enemies
			Bandit: level 1
			Bandit outlaw: Level 5 (boss)

		Player level 8
			Bandit outlaw: Level 5 (common enemy)
			Bandit: level 1
			Bandit Highwayman: 14 (boss)
			Bandit chief: (6??)

		Player level 15
			Bandit: 1 (rare weak enemy) (Easy, 33% of level or lower) (Full health: normal)
			Bandit thug: 9 (common enemy) (Normal, 66% of level or lower) (Full health: hard)
			Bandit Highwayman: 14 (very rare miniboss) (Hard, 100% of level or lower) (Full health: harder)
			Bandit Plunderer: 19 (boss) (Very hard, 125% of level) (Full health: very hard)

		Player level 30
			Bandit Plunderer: 19 (common enemy)
			Bandit: 1 (rare weak enemy)
			Bandit Marauder: 25 (boss)
			Bandit Outlaw: 5

		Modded (arena mod): https://www.nexusmods.com/skyrimspecialedition/mods/33487
			0.66x: Easy
			1.00x: Normal
			1.25x: Hard
			1.50x: Very Hard

	--------------------------------/;

	bool cheatMode = false 
	if cheatMode
		return 0
	endif

	bool arena = false ; arena mod:https://www.nexusmods.com/skyrimspecialedition/mods/33487/

	int playerLevel = playerref.GetLevel()
	int enemyLevel = target.GetLevel()
	float ret = 6.0


	float enemyHealth = target.GetActorValuePercentage("Health") * 100
	float levelRatio = ((enemyLevel as Float)/(playerLevel as Float)) * 100

	if !arena
		if levelRatio > 140 ; vanilla: underleveled | arena: hard
			ret = 10.0
		elseif levelRatio > 100 ; vanilla: very hard | arena: normal
			ret = 9.0
		elseif levelRatio > 70 ; vanilla: hard | arena: easy
			ret = 8.0
		elseif levelRatio > 35 ; vanilla: normal | arena: very easy
			ret = 7.5
		EndIf
	Else
		if levelRatio > 165 ; arena: underleveled
			ret = 10.0
		elseif levelRatio > 125 ; vanilla: underleveled | arena: very hard
			ret = 9.0
		elseif levelRatio > 100 
			ret = 8.0
		elseif levelRatio > 70 
			ret = 7.5
		elseif levelRatio > 35 
			ret = 6.5
		EndIf
	endif

	if target.IsBleedingOut()
		ret -= 7.5
	Else
		ret -= ((100.0 - (enemyHealth)) / 40.0) ; each 40% damage done takes off one level
	EndIf

	if !playerref.IsDetectedBy(target)
		ret -= 1
	endif

	if !target.IsInCombat()
		ret -= 1
	endif

	if target.GetSleepState() == 3
		ret -= 1
	endif

	if ret < 5.0
		ret = 5.0
	endif


		
	;debug.messagebox("Health: " + enemyHealth + " Level: " + levelRatio + " Difficulty: " + ret)

	return (ret)
endfunction

Function StruggleAnim(Actor Victim, Actor Aggressor, Bool Animate = True, bool victimStayDown = false, bool noIdle = false)
	;If !StruggleIsCreature
	if true
		If Animate
			If (Aggressor != Playerref)
	 			ActorUtil.AddPackageOverride(Aggressor, DoNothing, 100, 1)
				Aggressor.EvaluatePackage()
				Aggressor.SetRestrained()
				Aggressor.SetDontMove(true)
			Else
				Game.SetPlayerAiDriven()
				Game.ForceThirdPerson()
			Endif
			
			if playersuccubustrackingscriptmale.chanceRoll(50)
				victim.SetExpressionOverride(6, 100)
			Else
				victim.SetExpressionOverride(4, 100)
			endif
			
			ActorUtil.AddPackageOverride(Victim, DoNothing, 100, 1)

			;Aggressor.SetRestrained(true)
			;Aggressor.SetDontMove(true)

			victim.SetRestrained(true)
			victim.SetDontMove(true)
			Aggressor.SetDontMove(true)


			


			

			if Aggressor == playerref
				(posref).MoveTo(Aggressor) ; PosRef
			Else
				(posref).MoveTo(victim)
			endif

			float[] CenterLocation = new float[6]

			CenterLocation[0] = posref.GetPositionX()
			CenterLocation[1] = posref.GetPositionY()
			CenterLocation[2] = posref.GetPositionZ()
			CenterLocation[3] = posref.GetAngleX()
			CenterLocation[4] = posref.GetAngleY()
			CenterLocation[5] = posref.GetAngleZ()

			
			;Float AngleZ = Victim.GetAngleZ()
			;Aggressor.MoveTo(Victim, 0.0 * Math.Sin(AngleZ), 0.0 * Math.Cos(AngleZ))

			

			
			;If StruggleStanding
			if Aggressor == playerref
				CenterLocation[3] = 21
				CenterLocation[4] = 0
				CenterLocation[5] = 240

				int offset = Utility.RandomInt(20, 30)
				Aggressor.SetPosition(CenterLocation[0], CenterLocation[1] - 15, CenterLocation[2] + 6)
				Aggressor.SetAngle(CenterLocation[3] - 60, CenterLocation[4], CenterLocation[5] - offset)
			Else
				Aggressor.SetPosition(CenterLocation[0], CenterLocation[1], CenterLocation[2] + 6)
				Aggressor.SetAngle(CenterLocation[3], CenterLocation[4], CenterLocation[5])
			endif

			victim.SetPosition(CenterLocation[0], CenterLocation[1], CenterLocation[2] + 5)
			victim.SetAngle(CenterLocation[3], CenterLocation[4], CenterLocation[5])

			Victim.SetVehicle(posref) ; PosRef
			Aggressor.SetVehicle(posref) ; PosRef

		
			Debug.SendAnimationEvent(Victim, "Leito_nc_missionary_A1_S1")
			Debug.SendAnimationEvent(Aggressor, "Leito_nc_missionary_A2_S1")
				;Float Fangle = (Victim.GetHeadingAngle(Aggressor))
				;If ((Fangle < 110) && (Fangle > -110)) ; Returns FALSE for a hit in the back
				;	SendAnimationEvent(Victim, "Leito_Doggystyle_A1_S1")
				;	SendAnimationEvent(Aggressor, "Leito_Doggystyle_A2_S1")
				;Else
				;	SendAnimationEvent(Victim, "Zyn_Standing_A1_S1")
				;	SendAnimationEvent(Aggressor, "Zyn_Standing_A2_S1")
	
		Else

			;Aggressor.SetDontMove(false)


			Victim.SetVehicle(None) 
			Aggressor.SetVehicle(None) 


			Aggressor.SetRestrained(false)
			Aggressor.SetDontMove(false)

			victim.SetRestrained(false)
			victim.SetDontMove(false)
			ActorUtil.RemovePackageOverride(Victim, DoNothing)
			

			If (Aggressor != Playerref)
				Aggressor.SetRestrained(False)
				Aggressor.SetDontMove(false)
				ActorUtil.RemovePackageOverride(Aggressor, DoNothing)
			Else
				Game.SetPlayerAiDriven(False)
			Endif
			
			if !noIdle
				Debug.SendAnimationEvent(Aggressor, "IdleForceDefaultState")
			EndIf


			if !victimStayDown
				;Debug.SendAnimationEvent(Victim, "IdleForceDefaultState")
			endif
		Endif
	Endif
EndFunction

function ResetAttackState() ;run this if stuck
	runningAttack = false
	PlayerFollowerAlias.clear()
	PlayerFollowPartner = none
	debug.MessageBox("State Reset")
EndFunction

actor Function GetPlayerTalkPartner()
	if talker.IsInDialogueWithPlayer()
		return talker
	else 
	Actor kPlayerDialogueTarget
	Int iLoopCount = 10
	While iLoopCount > 0
		iLoopCount -= 1
		kPlayerDialogueTarget = Game.FindRandomActorFromRef(PlayerRef , 200.0)
		If kPlayerDialogueTarget != PlayerRef && kPlayerDialogueTarget.IsInDialogueWithPlayer() 
			talker = kPlayerDialogueTarget
			Return talker
		EndIf
	EndWhile
	endif
EndFunction

function npcEjaculate(actor ejaculator, actor target)
		if !canImpregnate(ejaculator)
			return
		endif

		int chance = main.GetPregnancyChance(target, false)

 		if (PlayerSuccubusTrackingScriptMale.chanceRoll(chance))
 			main.registerPregnancy(target)
 		endif
EndFunction

bool function isFollower(actor npc)
	return eff.XFL_IsFollower(npc)
endfunction

actor Function getRandomFollower() ; should always return a valid follower
	int followercount = getFollowerCount()

	if followercount < 1
		return None
	Else
		int id = Utility.RandomInt(0, followercount - 1)
		actor follower = eff.XFL_GetFollower(id)

		if (follower.GetActorValue("WaitingForPlayer") == 2) && follower.Is3DLoaded()
			return follower
		endif

	endif

endfunction

int function getFollowerCount()
	return eff.XFL_GetCount()
EndFunction

bool function isAllowedToBeRaped(actor npc)
	if npc.IsInCombat()
		return False
	endif

	if main.isActorPregnant(npc)
		return False
	endif

	if CanSex(npc)
		int gender = sexlab.GetGender(npc)

		if gender == 1
			
			if allowedVictimsMode == 1
				return true
			Else
				return ActorIsHelpless(npc)
			endif
		endif
	endif

	return false
EndFunction

int SlaveMasterID = 0
int SlaveStartID = 1
referencealias function getSlaveQuestAlias(int id)
	return SlaveQuest.GetNthAlias(id) as ReferenceAlias
EndFunction

bool function isEnslaved(actor target)
	return target.IsInFaction(SuccubusSlaveFaction)
endfunction

Form function getBondageItemFromInventory(actor npc) ; returns one item (in the shape of a form) of a piece of bondage gear in an inventory
	Int iFormIndex = npc.GetNumItems()
	While iFormIndex > 0
		iFormIndex -= 1
		Form kForm = npc.GetNthForm(iFormIndex)
		If kForm.HasKeyword(Keyword.GetKeyword("zbfWornDevice"))
			return kform
		EndIf
	EndWhile
EndFunction

function transferItem(actor giver, actor reciever, form item)
	giver.RemoveItem(item, 1, false, reciever)
EndFunction

function openSlaveMenu(actor slave)
	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int exit = 7
	Int inventory = 1
	Int release = 5
	Int strip = 2

	wheelMenu.SetPropertyIndexString("optionLabelText", exit, "Cancel")
	wheelMenu.SetPropertyIndexString("optionLabelText", inventory, "Inventory")
	wheelMenu.SetPropertyIndexString("optionLabelText", release, "Release")
	wheelMenu.SetPropertyIndexString("optionLabelText", strip, "Strip")

	wheelMenu.SetPropertyIndexBool("optionEnabled", exit, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", inventory, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", release, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", strip, true)

	int ret = wheelMenu.OpenMenu(slave)

	if ret == inventory
		slave.OpenInventory(true)
	elseif ret == release
		release(slave)
	elseif ret == strip
		StripNPCCompletely(slave)
	Else
		return
	endif
EndFunction

;allowedVictimsMode = 1 ;1 = anyone, 2 = slaves only

function openFollowerMenu(actor follower)
	trackingNPCCombat = false
	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int exit = 7
	Int rapemode = 1
	Int master = 5
	Int fix = 4

	wheelMenu.SetPropertyIndexString("optionLabelText", exit, "Cancel")
	wheelMenu.SetPropertyIndexString("optionLabelText", rapemode, "Rape Targets...")
	wheelMenu.SetPropertyIndexString("optionLabelText", master, "Set as Master")
	wheelMenu.SetPropertyIndexString("optionLabelText", fix, "Fix...")

	wheelMenu.SetPropertyIndexBool("optionEnabled", exit, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", rapemode, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", master, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", fix, true)

	int ret = wheelMenu.OpenMenu(follower)

	if ret == rapemode
		setRapeMode()
	elseif ret == master
		SetMaster(follower)
	elseif ret == fix
		Debug.Notification("Trying to fix follower...")

		form left = follower.GetEquippedWeapon(true)
		form right = follower.GetEquippedWeapon(false)
		follower.UnequipItem(left, false, true)
		follower.UnequipItem(right, false, true)
		follower.EquipItem(left, false, true)
		follower.EquipItem(right, false, true)

		debug.Notification("Resetting update timer...")
		;registerforsingleupdate(10)
	Else
		return
	endif
EndFunction

function setRapeMode()
	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int exit = 7
	Int slaves = 1
	Int anyone = 5

	wheelMenu.SetPropertyIndexString("optionLabelText", exit, "Cancel")
	wheelMenu.SetPropertyIndexString("optionLabelText", slaves, "rape slaves only")
	wheelMenu.SetPropertyIndexString("optionLabelText", anyone, "rape anyone")

	wheelMenu.SetPropertyIndexBool("optionEnabled", exit, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", slaves, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", anyone, true)

	int ret = wheelMenu.OpenMenu()

	if ret == slaves
		allowedVictimsMode = 2
		debug.Notification("Followers will only rape slaves and enemies")
	elseif ret == anyone
		allowedVictimsMode = 1
		debug.Notification("Followers will rape anyone")
	Else
		return
	endif
EndFunction

function openTraumaMenu(actor slave)
	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int exit = 7
	Int enslave = 1
	int inventory = 5

	wheelMenu.SetPropertyIndexString("optionLabelText", exit, "Cancel")
	wheelMenu.SetPropertyIndexString("optionLabelText", enslave, "Enslave")
	wheelMenu.SetPropertyIndexString("optionLabelText", inventory, "Inventory")

	wheelMenu.SetPropertyIndexBool("optionEnabled", exit, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", enslave, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", inventory, true)

	int ret = wheelMenu.OpenMenu(slave)

	if ret == enslave
		enslave(slave)
	elseif ret == inventory
		slave.OpenInventory(true)
	Else
		return
	endif
EndFunction

bool Function IsRestrained(actor npc) ; returns true if the npc has on some devious devices
	return npc.WornHasKeyword(Keyword.GetKeyword("zbfWornDevice")) ;zaz devices

EndFunction


function enslave(actor slave)

	int id = getNextOpenSlaveSlot()

	if id == -1
		debug.Notification("Maximum number of slaves reached")
		return
	else

		if !getBondageItemFromInventory(slave) ; no bondage gear on npc
			form gear = getBondageItemFromInventory(playerref)

			if gear
				transferItem(playerref, slave, gear)
			Else
				Debug.Notification("No bondage gear available")
				return
			endif
		endif
		; all clear from here on

		StripNPCCompletely(slave)
		slave.setav("Aggression", 0)
		slave.setav("Confidence", 0)
		slave.setav("Morality", 0)
		ReferenceAlias slavealias = getSlaveQuestAlias(id)
		slavealias.ForceRefTo(slave)
		slave.EvaluatePackage()
		slavereferencescript slavescript = slavealias as slavereferencescript


		Trauma(slave, false)

		Utility.Wait(5)
		slavescript.manageBondage()
	endif
endfunction

function release(actor slave)
	getSlaveActorAlias(slave).Clear()
endfunction

int slaveslotcount = 21 ; final slot id

referencealias function getSlaveActorAlias(actor slave) ;get alias of said actor

	int currentSlot = SlaveStartID

	while currentSlot < (SlaveStartID + slaveslotcount)
		ReferenceAlias salias = getSlaveQuestAlias(currentSlot)


		if salias.GetActorRef() == slave
			return salias
		endif


		currentSlot += 1
	EndWhile

	return none
endfunction 

int function getNextOpenSlaveSlot()

	int currentSlot = SlaveStartID

	while currentSlot < (SlaveStartID + slaveslotcount)
		ReferenceAlias salias = getSlaveQuestAlias(currentSlot)


		if !salias.GetActorRef()
			return currentSlot
		endif

		currentSlot += 1
	EndWhile


	return -1 ; return -1 if none open
endfunction

function resetSlaveAIs()


	
	int currentSlot = SlaveStartID

	while currentSlot < (SlaveStartID + slaveslotcount)
		ReferenceAlias salias = getSlaveQuestAlias(currentSlot)


		if salias.GetActorRef()
			salias.GetActorRef().ResetAI()
		endif

		currentSlot += 1
	EndWhile



EndFunction

function SetMaster(actor master) 
	getSlaveQuestAlias(SlaveMasterID).ForceRefTo(master)
	resetSlaveAIs()
	debug.Notification("Set new slave master")
endfunction
actor function TryFindRapeTarget(actor rapist) ; returns none if no target found
	; this function finds a single random target, running it again and again may give different results.

	float radius = 6400 ; 300 foot radius
	actor target = Game.FindRandomActorFromRef(rapist, radius)

	if target == None
		return None
	else
		if isAllowedToBeRaped(target)
			return target
		endif
	endif
EndFunction


bool function DoFollowerRapeEvent()
	if getFollowerCount() == 0 ; dont waste cpu cycles
		return False
	EndIf

	if playerref.IsInCombat()
		return False
	EndIf
	int FollowerAttemptsLeft = 5

	while FollowerAttemptsLeft > 0
		int ScanAttemptsLeft = 5
		actor attacker = getRandomFollower()

		while ScanAttemptsLeft > 0
			actor target = TryFindRapeTarget(attacker)

			if target == None
				ScanAttemptsLeft = ScanAttemptsLeft - 1
				Utility.wait(0.5)
			Else
				NPCRape(attacker, target)
				FollowerAttemptsLeft = 0
				ScanAttemptsLeft = 0
				return true
			endif
		endwhile

		FollowerAttemptsLeft = FollowerAttemptsLeft - 1
	endwhile
endfunction

bool function OpenAcceptMenu(actor npc)
	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int accept = 1
	Int cancel = 5

	wheelMenu.SetPropertyIndexString("optionLabelText", cancel, "Decline")
	wheelMenu.SetPropertyIndexString("optionLabelText", accept, "Accept")

	wheelMenu.SetPropertyIndexBool("optionEnabled", cancel, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", accept, true)


	int dec = wheelMenu.OpenMenu(npc)

	if dec == 1
		return true
	Else
		return false
	endif

EndFunction

Function OpenNpcMenu(actor npc) 


	npc.AddToFaction(SuccubusDialogueFaction)
	bool movingNPC = false
	bool femalePlayer = appearsFemale(playerref)
	playerref.SetDontMove(true)
	float distance = npc.GetDistance(playerref)
	utility.wait(0.1)

	if npc.GetDistance(playerref) != distance
		SetAsFollower(npc, true)
		movingNPC = true
	endif

	npc.SetLookAt(playerref, abPathingLookAt = false)
	npc.SetExpressionOverride(5, 100)

	bool success = false
	bool failure = false
	bool wasbribed = false
	int act = -1

	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int exit = 7
	Int seduce = 1
	Int pay = 5
	int offersex = 6
	bool prost = isProstitute(npc)

	wheelMenu.SetPropertyIndexString("optionLabelText", exit, "Cancel")
	wheelMenu.SetPropertyIndexString("optionLabelText", seduce, "Seduce")

	wheelMenu.SetPropertyIndexBool("optionEnabled", exit, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", seduce, true)

	if prost
		wheelMenu.SetPropertyIndexString("optionLabelText", pay, "Purchase sex")
		wheelMenu.SetPropertyIndexBool("optionEnabled", pay, true)
	endif

	if femalePlayer && !appearsFemale(npc)
		wheelMenu.SetPropertyIndexString("optionLabelText", offersex, "Offer sex service")
		wheelMenu.SetPropertyIndexBool("optionEnabled", offersex, true)
	endif

	npc.say(hello)
	int ret = wheelMenu.OpenMenu(npc)


	int playerSV = GetPlayerSexualValue()
	int npcSV = GetNPCSexualValue(npc)

	
	int desirebonus = NPCDesiresPlayerGender(npc)
	; 1 hates
	; 2 desires | this gives a sexual value bonus
	; 3 will have sex but does not desire, no sexual value bonus
	; 4 will not have sex 

	if desirebonus == 2
		playerSV += 85
	elseif desirebonus == 3

	elseif desirebonus == 4 ;not sexual preference, but there's still a slim chance
		npcSV += 120
	Else
		npcSV += 400
	endif




	if ret == seduce
		;Debug.Notification("Seducing")
		
		if playerSV >= npcSV
			success = true
			lastSelectedAct = -1
		else 
			failure = true
		endif
			
			

	elseif ret == offersex

		float currentTime = Utility.GetCurrentGameTime()
		float lastBuyTime = GetNPCLastProstTime(npc)
		if lastBuyTime < 0
			lastBuyTime = -100
		EndIf
		if (currentTime - lastBuyTime) < 3.0
			float timeLeft = (lastBuyTime + 3.0) - currentTime 
			timeLeft = timeLeft * 100.0 ;300 points starting, decreses over time

			npcSV += (timeLeft as int)
		endif

		if GetTimeOfDay() == 1 ; prostitution should be done at night
			playerSV -= 85
		endif

		if playerSV >= npcSV

			if playersuccubustrackingscriptmale.chanceRoll(75)
				npc.Say(HowMuch)
			endif

			act = openSexActMenu(playerref)

			if act > -1
				int price = (150.0 * GetPrudeMult(GetNPCPrudishness(npc))) as int

				

				int wealth = GetNPCWealth(npc)

				if wealth == 0
					price = (price * 0.1) as int
				elseif wealth == 1
					price = (price * 1.3 ) as int
				Else
					;nothing
				endif

				int level = npc.GetLevel()
				if level < 6
					price -= level
				Else
					price += level
				endif

				price = ((price as float) * (sexPriceMults[act])) as int
				if price < 1
					price = 1
				endif

				debug.Notification(npc.getdisplayname() + " offers " + price + " gold for your services")

				bool dec = OpenAcceptMenu(npc)

				if dec
						success = true
						;payedPlayer = true
						playerOwesService = true
						wasbribed = true
		
						Playerref.additem(Gold, aiCount = price)
						lastAcceptedProstPrice = price
						lastSelectedAct = act
						SetNPCLastProstTime(npc)
		
				Else
					failure = true
				endif
			Else
				failure = true
			endif
		else 
			failure = true
		endif

			

	elseif ret == pay

		act = openSexActMenu(npc)
		int offer = GetNPCOffer(npc, playersv, npcsv)
		offer = ((offer as float) * (sexPriceMults[act])) as int

		if offer < 1
			offer = 1
		endif

		debug.Notification(npc.getdisplayname() + " offers her services for " + offer + " gold")




		bool dec = OpenAcceptMenu(npc)

		if dec
			if playerref.GetItemCount(gold) >= offer
					success = true
					wasbribed = true
	
					Playerref.RemoveItem(Gold, aiCount = offer)
					npc.AddItem(gold, aiCount = offer, abSilent = true)
					lastSelectedAct = act
			Else
				debug.Notification("You do not have enough gold")
				failure = true
			endif
		Else
			failure = true
		endif

		

	Else 

		
		
	endif



	if success ; sex time
		npc.SetExpressionOverride(2, 100)
		if !movingNPC
			SetAsFollower(npc, true)
		endif
		
		if wasBribed 
			npc.Say(Bribed)
		else	
			MarkNPCSeduced(npc) 
			npc.say(yes)
		endif

	Elseif failure ;rejected

		npc.SetExpressionOverride(4, 100)
		if movingNPC
			SetAsFollower(npc, false)
		endif
		npc.say(no)

	Else ;cancel
		if movingNPC
			SetAsFollower(npc, false)
		endif

		npc.say(Bye)
	endif

	playerref.SetDontMove(false)
	npc.RemoveFromFaction(SuccubusDialogueFaction)

	Utility.wait(3)
	npc.ClearExpressionOverride()

endfunction

bool function isProstitute(actor npc)
	return npc.IsInFaction(jobInnServer) || npc.IsInFaction(FavorJobsBeggarFaction) || npc.IsInFaction(MarkarthTempleofDibellaFaction)
EndFunction

int Function GetNPCOffer(actor npc, int playersv, int npcsv) 
	
	int wealth = GetNPCWealth(npc)
	int ret = npcsv - playersv

	if wealth == 0 ;poor
		
	ElseIf wealth == 2
		ret *= 10

	elseif wealth == 1
		ret *= 30
	endif
		
	return ret

endfunction



int function GetNPCWealth(actor npc) ;0 - poor | 1 - wealthy | 2 - normal |
	armor clothing = npc.GetWornForm(0x00000004) as Armor

	if npc.IsInFaction(FavorJobsBeggarFaction)
		return 0
	elseif clothing.IsClothingRich()
		return 1
	else 
		return 2
	endif


EndFunction

Function OpenSexStartMenu(actor npc)

	npc.SetExpressionOverride(2, 100)
	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int exit = 7
	Int seduce = 1
	Int cancel = 5

	int refund = 4

	wheelMenu.SetPropertyIndexString("optionLabelText", exit, "Exit")
	wheelMenu.SetPropertyIndexString("optionLabelText", cancel, "Cancel Sex")
	wheelMenu.SetPropertyIndexString("optionLabelText", seduce, "SEX")

	wheelMenu.SetPropertyIndexBool("optionEnabled", exit, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", cancel, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", seduce, true)

	if playerOwesService
		wheelMenu.SetPropertyIndexString("optionLabelText", refund, "refund")
		wheelMenu.SetPropertyIndexBool("optionEnabled", refund, true)
	endif

	int ret = wheelMenu.OpenMenu(npc)

	npc.ClearExpressionOverride()

	if ret == exit
		
	elseif ret == refund
		SetAsFollower(npc, false)
		playerOwesService = false

		if playerref.GetItemCount(gold) >= lastAcceptedProstPrice
			Playerref.RemoveItem(Gold, aiCount = lastAcceptedProstPrice)
		Else
			if playersuccubustrackingscriptmale.chanceRoll(25)
				npc.StartCombat(playerref)
			endif
			AddBounty(lastacceptedprostprice, npc.GetCrimeFaction(), silent = false, violent = false)
		endif
		lastSelectedAct = -1
	elseif ret == cancel
		SetAsFollower(npc, false)
		if playerOwesService
			playerOwesService = False

			if playersuccubustrackingscriptmale.chanceRoll(25)
				npc.StartCombat(playerref)
			endif
			AddBounty(lastacceptedprostprice, npc.GetCrimeFaction(), silent = false, violent = false)

		endif
		lastSelectedAct = -1
	Elseif ret == seduce
		if playerOwesService
			playerOwesService = false
		endif
		SetAsFollower(npc, false)
		


		if appearsFemale(playerref) && !appearsFemale(npc) ;straight, but player is female
			dosex(npc, playerref, tags = lastSelectedAct) ;player is not dominant
		Else
			dosex(playerref, npc, tags = lastSelectedAct) ;player is otherwise dominant
		endif

	endif

	lastSelectedAct = -1

	

	

endfunction


int Function GetPlayerSexualValue()
	;low - 19 (level 5 player with 23 speech)
	;medium - 78 (level 21 player with 45 speech)
	;high - 155(level 33 player with 85 speech, one thane and one house)

	
	int playerSpeech = (((playerref.GetActorValue("speechcraft") as int) - 15) * 1.2) as int ; speechpoints gained times 1.2 (max gain of 102 value)
	int playerLevel = playerref.Getlevel() * 2
	int playerThaneCount = 0
	;int playerWeight = (playerref.GetActorBase().GetWeight() as int) / 3 ; balanced by giving levels double output
	;int playerPP = ((SuccubusQuest as playersuccubustrackingscriptmale).SuccubusPlayerPP.GetValue() as int) / 1000 ; balanced by making speech points 1.2
	int slayedAlduinStat = 0
	int endedWar = 0
	int propertyOwned = Game.QueryStat("Houses Owned") * 2


	;----- Thanes -----
	If (FavorJarlsMakeFriends.WhiterunImpGetOutofJail > 0 || FavorJarlsMakeFriends.WhiterunSonsGetOutofJail > 0)
		playerThaneCount += 1
	EndIf
	If (FavorJarlsMakeFriends.EastmarchImpGetOutofJail > 0 || FavorJarlsMakeFriends.EastmarchSonsGetOutofJail > 0)
		playerThaneCount += 1
	EndIf
	If (FavorJarlsMakeFriends.FalkreathImpGetOutofJail > 0 || FavorJarlsMakeFriends.FalkreathSonsGetOutofJail > 0)
		playerThaneCount += 1	
	EndIf
	If (FavorJarlsMakeFriends.HaafingarImpGetOutofJail > 0 || FavorJarlsMakeFriends.HaafingarSonsGetOutofJail > 0)
		playerThaneCount += 1	
	EndIf
	If (FavorJarlsMakeFriends.HjaalmarchImpGetOutofJail > 0 || FavorJarlsMakeFriends.HjaalmarchSonsGetOutofJail > 0)
		playerThaneCount += 1	
	EndIf
	If (FavorJarlsMakeFriends.PaleImpGetOutofJail > 0 || FavorJarlsMakeFriends.PaleSonsGetOutofJail > 0)
		playerThaneCount += 1	
	EndIf
	If (FavorJarlsMakeFriends.ReachImpGetOutofJail > 0 || FavorJarlsMakeFriends.ReachSonsGetOutofJail > 0)
		playerThaneCount += 1
	EndIf
	If (FavorJarlsMakeFriends.WinterholdImpGetOutofJail > 0 || FavorJarlsMakeFriends.WinterholdSonsGetOutofJail > 0)
		playerThaneCount += 1
	EndIf
	If (FavorJarlsMakeFriends.RiftImpGetOutofJail > 0 || FavorJarlsMakeFriends.RiftSonsGetOutofJail > 0)
		playerThaneCount += 1
	EndIf

	playerThaneCount = playerThaneCount * 5

	if SlayedAlduin.IsCompleted()
		slayedAlduinStat = 10
	endif

	if wonCivilWar.IsCompleted()
		endedWar = 10
	endif

	;debug.MessageBox("property: " + propertyOwned) ;probably ok
	float finalMult = 1

	if playerref.GetRace().HasKeyword(Keyword.GetKeyword("IsBeastRace"))
		finalMult = 0.5
	endif

	return ((playerSpeech + playerLevel + playerThaneCount + slayedalduinStat + endedWar + propertyOwned) * finalMult) as int
	
endfunction

int Function GetNPCSexualValue(actor npc)
	
	;low - 60 (prude level 2 npc with relationship rank 0 with player)
	;medium - 115 (prude level 5 protected npc with relationship 0 with player)
	;high - 523 (a prude level 9 married essential npc at day time with relationship rank 0 with player)
	int value = 0

	actorbase npcBase = npc.GetActorBase()
	int prank = GetNPCPrudishness(npc)
	float plev = GetPrudeMult(prank)
	bool unique = npcBase.isunique()
	bool protected = npcBase.IsProtected()
	bool essential = npcBase.IsEssential()
	int timeOfDay = GetTimeOfDay() ; 0 - day | 1 - morning/dusk | 2 - Night
	int RelationshipRank = npc.GetRelationshipRank(playerref)
	bool hasSpouse = npc.HasAssociation(Spouse)
	bool hasChild = false 
	bool hasbeenseduced = HasNPCBeenSeduced(npc)
	actor husband

	bool isJarl = npc.IsInFaction(JarlFaction)
	bool isJarlEmployee = npc.IsInFaction(CourtMageFaction) || npc.isinfaction(StewardFaction)
	bool isGuard = npc.IsGuard()


	if unique	

		if hasSpouse
			;husband = GetSpouse(npc) 
		endif


		if unique
			value += (plev * 100) as int
		EndIf

		if protected
			value += (plev * 15) as int
		EndIf

		if essential
			value += (plev * 20) as int
		EndIf

		if timeOfDay == 0
			value += 10
		ElseIf timeOfDay == 2
			value -= 10
		EndIf

		if RelationshipRank < 0
			value += RelationshipRank * 100
		elseif RelationshipRank > 0
			value -= RelationshipRank * 50
		endif



		If (FavorJarlsMakeFriends.WhiterunImpGetOutofJail > 0 || FavorJarlsMakeFriends.WhiterunSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionWhiterun)
				value -= 20
			endif
		EndIf
		If (FavorJarlsMakeFriends.EastmarchImpGetOutofJail > 0 || FavorJarlsMakeFriends.EastmarchSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionEastmarch)
				value -= 20
			endif
		EndIf
		If (FavorJarlsMakeFriends.FalkreathImpGetOutofJail > 0 || FavorJarlsMakeFriends.FalkreathSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionFalkreath)
				value -= 20
			endif
		EndIf
		If (FavorJarlsMakeFriends.HaafingarImpGetOutofJail > 0 || FavorJarlsMakeFriends.HaafingarSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionHaafingar)
				value -= 20
			endif
	
		EndIf
		If (FavorJarlsMakeFriends.HjaalmarchImpGetOutofJail > 0 || FavorJarlsMakeFriends.HjaalmarchSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionHjaalmarch)
				value -= 20
			endif
		EndIf
		If (FavorJarlsMakeFriends.PaleImpGetOutofJail > 0 || FavorJarlsMakeFriends.PaleSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionPale)
				value -= 20
			endif
		EndIf
		If (FavorJarlsMakeFriends.ReachImpGetOutofJail > 0 || FavorJarlsMakeFriends.ReachSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionReach)
			value -= 20
			endif
		EndIf
		If (FavorJarlsMakeFriends.WinterholdImpGetOutofJail > 0 || FavorJarlsMakeFriends.WinterholdSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionWinterhold)
				value -= 20
			endif
		EndIf
		If (FavorJarlsMakeFriends.RiftImpGetOutofJail > 0 || FavorJarlsMakeFriends.RiftSonsGetOutofJail > 0)
			if npc.IsInFaction(CrimeFactionRift)
				value -= 20
			endif
		EndIf

		if hasbeenseduced
			value -= 100
		EndIf

		if hasSpouse && (prank > 1)
			value += 150
		EndIf

		if isJarl
			value += 50
		EndIf

		if isJarlEmployee
			value += (10 * plev) as Int
		endif

		

	Else ;randoms

		value = 60 + (prank * 10)

		if timeOfDay == 0
			value += 10
		ElseIf timeOfDay == 2
			value -= 10
		EndIf

		if RelationshipRank < 0
			value += RelationshipRank * 100
		elseif RelationshipRank > 0
			value -= RelationshipRank * 50
		endif

		if isGuard
			value += 30
		endif

		
	endif

	return value



endfunction

function MarkNPCSeduced(actor npc)
	npc.AddToFaction(SuccubusSeduced)
EndFunction

bool function HasNPCBeenSeduced(actor npc)
	return npc.IsInFaction(SuccubusSeduced)
endfunction

int Function GetTimeOfDay() global ; 0 - day | 1 - morning/dusk | 2 - Night
	float hour = GetCurrentHourOfDay()

	if (hour < 4) || (hour > 20 ) ; 8:01 to 3:59. night
		return 2
	elseif ((hour >= 18) && (hour <= 20))  || ((hour >= 4) && (hour <= 6)) ; morning/dusk
		return 1
	Else
		return 0
	endif
		

EndFunction

float Function GetCurrentHourOfDay() global
 
	float Time = Utility.GetCurrentGameTime()
	Time -= Math.Floor(Time) ; Remove "previous in-game days passed" bit
	Time *= 24 ; Convert from fraction of a day to number of hours
	Return Time
 
EndFunction

int function GetNPCPrudishness(actor npc) ;0, whore - 10, prude
	
	if !npc.IsInFaction(succubusprude)
		npc.AddToFaction(succubusprude)
		npc.SetFactionRank(succubusprude, Utility.RandomInt(0, 10))
	endif

	return npc.GetFactionRank(succubusprude)
EndFunction

float function GetPrudeMult(int prudeleve)
	float[] prudeMult = new float[11]

	prudeMult[0] = 0.5
	prudeMult[1] = 0.6
	prudeMult[2] = 0.7
	prudeMult[3] = 0.8
	prudeMult[4] = 0.9
	prudeMult[5] = 1
	prudeMult[6] = 1.2
	prudeMult[7] = 1.4
	prudeMult[8] = 1.6
	prudeMult[9] = 1.8
	prudeMult[10] = 2

	return prudeMult[prudeleve]


EndFunction

function onPlayerHit(objectreference aggressor) ; function called when player takes damage from a source. must be set up and called from a quest alias
	int odds = 25
	float healththresh = 0.34
	;int odds = 50 
	;float healththresh = 0.90
	;todo optional - morality required to attack player

	if playersuccubustrackingscriptmale.chanceRoll(odds)
		if (PlayerRef.GetActorValuePercentage("health") < healththresh)
			Actor target = aggressor as Actor
			if target.GetDistance(playerref) < 256	
				if target.GetRace().HasKeywordString("ActorTypeNPC")
					if !(isFemale(target))
						if !(target.GetCrimeFaction())
							AttemptAttack(target, playerref)
						endif
					endif
				endif
			endif
		endif
	endif
	


EndFunction

function SetAsFollower(actor npc, bool set) ; follower in literal sense, not combat ally
	if set
		PlayerFollowerAlias.ForceRefTo(npc)
		PlayerFollowPartner = npc
	Else
		PlayerFollowerAlias.clear()
		PlayerFollowPartner = none
	endif
EndFunction



Function StripNPC(actor npc)
	
	form chest = npc.GetWornForm(0x00000004)

	if chest
		strip(chest, npc, false)
		Return 
	endif

	form helmet = npc.GetWornForm(0x00000002)

	if helmet
		strip(helmet, npc, false)
		Return 
	endif

	form boots = npc.GetWornForm(0x00000080)

	if boots
		strip(boots, npc, false)
		Return 
	endif

	form hands = npc.GetWornForm(0x00000008)

	if hands
		strip(hands, npc, false)
		Return 
	endif

endfunction


Function StripNPCCompletely(actor npc)
	
	form chest = npc.GetWornForm(0x00000004)

	if chest && !chest.HasKeyword(Keyword.GetKeyword("zbfWornDevice"))
		strip(chest, npc, false)
	endif

	Utility.Wait(0.3)

	form helmet = npc.GetWornForm(0x00000002)

	if helmet && !helmet.HasKeyword(Keyword.GetKeyword("zbfWornDevice"))
		strip(helmet, npc, false)
	endif

	Utility.Wait(0.3)

	form boots = npc.GetWornForm(0x00000080)

	if boots && !boots.HasKeyword(Keyword.GetKeyword("zbfWornDevice"))
		strip(boots, npc, false)
	endif

	Utility.Wait(0.3)

	form hands = npc.GetWornForm(0x00000008)

	if hands && !hands.HasKeyword(Keyword.GetKeyword("zbfWornDevice"))
		strip(hands, npc, false)
	endif

	Utility.Wait(0.3)
	strip(npc.GetEquippedObject(0) as form, npc)
	strip(npc.GetEquippedObject(1) as form, npc) 

endfunction

bool function moveNPC(actor walker, actor victim)
	float distances = walker.GetDistance(victim)
	int timeout = 120
	bool arrived = false

	SuccubusWalkAttacker.ForceRefTo(walker)
	SuccubusWalkVictim.ForceRefTo(victim)

	while (timeout != 0) && !arrived
		distances = walker.GetDistance(victim)

		if distances < 250
			arrived = true
		endif

		Utility.Wait(1)
		timeout -= 1
	EndWhile

	SuccubusWalkVictim.Clear()
	SuccubusWalkAttacker.Clear()
	return arrived
endfunction

bool function ActorIsHelpless(actor victim) ; cannot resist rape? 
	return victim.HasMagicEffect(succubusTraumaSpell.GetNthEffectMagicEffect(0)) || isEnslaved(victim)
endfunction

function RemoveFromFollowers(actor follower) ; dismiss silently
	eff.XFL_RemoveFollower(follower, iMessage = 6, iSayLine = 0)
EndFunction

function AddToFollowers(actor follower) 
	if !follower.Is3DLoaded()
		return
	endif
	eff.XFL_AddFollower(follower)
	eff.XFL_SetSandbox(follower)
EndFunction

bool function isFemale(actor acto)
	if SexLab.GetGender(acto) == 0
		return False
	else 
		return true
	endif
EndFunction

bool function appearsFemale(actor acto) ;may fail to spot some trans leveled actors, those actors will get "appears male"
	return (isFemale(acto) || (acto.getleveledactorbase().getsex() == 1))
endfunction

bool function isTrans(actor acto) 
	if appearsFemale(acto) && (!isFemale(acto))
		return true
	Else
		return false
	endif
endfunction

function TrackCombatRape(actor attacker, actor victim)
	if trackingNPCCombat
		Return
	EndIf

	if sexlab.GetGender(victim) == 0
		Return
	endif

	if ActorIsHelpless(victim)
		Return 
	endif

	
	
	trackingNPCCombat = true

	float healthThreshold = 1

	if (attacker.GetLevel() + 1) > victim.GetLevel()
		healthThreshold = 0.65
	Else
		healthThreshold = 0.45
	endif

	while trackingNPCCombat
		Utility.Wait(2)

		if (victim.GetActorValuePercentage("health") < healthThreshold) && !victim.IsDead() && !attacker.IsDead() && victim.IsInCombat()
			NPCRape(attacker, victim, true)
			trackingNPCCombat = false

		endif
		if !attacker.IsInCombat() || !victim.IsInCombat() || attacker.IsDead() || victim.IsDead()
			trackingNPCCombat = false
		endif
	EndWhile
	
EndFunction


function failNPCAttack(actor attacker, actor victim)
	StruggleAnim(victim, attacker, false, false, True)
	attacker.pushactoraway(victim, 0)
	victim.pushactoraway(attacker, 3)
	FXMeleePunchLargeS.Play(Attacker)
	victim.StartCombat(attacker)
	victim.DrawWeapon()
	attacker.StartCombat(victim)
	
	Utility.wait(2)

	victim.StartCombat(attacker)
	attacker.StartCombat(victim)
endfunction


Function NPCRape(actor attacker, actor victim, bool forceCombatMode = false)
	bool victimInCombat = (forceCombatMode) || (victim.IsInCombat())

	
	int minDistance = 196 ; about 9 feet

	float distances = attacker.GetDistance(victim)

	if victimInCombat
		Calm(victim)
	endif

	

	if (distances > minDistance)
		
		bool arrived 
		if victimInCombat
			if distances > 600 ; about 30 feet, more room for error in combat
				arrived = false
			Else
				arrived = true
			endif
		else
			RemoveFromFollowers(attacker)
			arrived = moveNPC(attacker, victim)	
		endif

		

		if !arrived || victim.IsDead() || attacker.IsDead()
			if !isFollower(attacker)
				AddToFollowers(attacker)
			endif
			Return
		EndIf
	endif

	


	bountySet = false
	targetHasCrimeFaction = victim.GetCrimeFaction() as Bool
	victim.StopCombat()

	if !ActorIsHelpless(victim)
		StruggleAnim(victim, attacker)
    endif
	SuccCrimeSpell.cast(playerref)	
	SuccCrimeSpell.cast(playerref)

	int failureStage = -1 ; npcs act strange if fail

	;if victimInCombat
	;	failureStage = Utility.RandomInt(1, 15) ; 30 percent chance of fail
	;EndIf

	if !ActorIsHelpless(victim)
		;---------------------------------------------strip
		float speed = Utility.RandomFloat(0.5, 1.0)
		; helmet
		Utility.Wait(speed)
		strip(victim.GetWornForm(0x00000002), victim)

		;failureStage -= 1
		;if failureStage == 0
		;	failNPCAttack(attacker, victim)
		;	return
		;endif

		;gauntlet
		Utility.Wait(speed)
		strip(victim.GetWornForm(0x00000008), victim)

		;failureStage -= 1
		;if failureStage == 0
		;	failNPCAttack(attacker, victim)
		;	return
		;endif
		;feet
		Utility.Wait(speed)
		strip(victim.GetWornForm(0x00000080), victim)

		;failureStage -= 1
		;if failureStage == 0
		;	failNPCAttack(attacker, victim)
		;	return
		;endif

		;left hand
		Utility.Wait(speed)
		strip(victim.GetEquippedObject(0) as form, victim)
		;right hand
		Utility.Wait(speed/2.0)
		strip(victim.GetEquippedObject(1) as form, victim) 

		;failureStage -= 1
		;if failureStage == 0
		;	failNPCAttack(attacker, victim)
		;	return
		;endif

		;armor!
		Utility.Wait(speed)
		strip(victim.GetWornForm(0x00000004), victim)
		Utility.Wait(speed)

		;failureStage -= 1
		;if failureStage == 0
		;	failNPCAttack(attacker, victim)
		;	return
		;endif
		;-------------------------------------------------------
	endif

	SuccCrimeSpell.cast(playerref)
	SuccCrimeSpell.cast(playerref)

	if !ActorIsHelpless(victim)
		StruggleAnim(victim, attacker, false, true) ;end struggle anim
    endif
	victim.SetDontMove(true)

	if !victimInCombat 
		bool violent = true

		if isEnslaved(victim)
			if playersuccubustrackingscriptmale.chanceRoll(75)
				violent = false
			endif
		endif

		doSex(attacker, victim, violent)
	Else
		Trauma(victim)	
		form left = attacker.GetEquippedWeapon(true) ; fixes "stuck animations" bug
		form right = attacker.GetEquippedWeapon(false)
		attacker.UnequipItem(left, false, true)
		attacker.UnequipItem(right, false, true)
		attacker.EquipItem(left, false, true)
		attacker.EquipItem(right, false, true) 
		


	EndIf


	victim.SetDontMove(false)

	if !isFollower(attacker)
		AddToFollowers(attacker)
	endif



endfunction

function toggleCombat() ;huge hack
	ConsoleUtil.ExecuteCommand("tcai")

endfunction


function playerAttackFailedEvent(actor attacker) ;called when player loses a rape event to an attacker
	doSex(attacker, playerref, true, isFemale(attacker)) ; player lost, will now be raped
EndFunction


function strip(form item, actor target, bool doImpulse = true)
	if item
		objectreference thing = target.dropObject(item)
		thing.SetPosition(thing.GetPositionx(), thing.GetPositionY(), thing.GetPositionZ() + 64)
		if doImpulse
			thing.applyHavokImpulse(Utility.RandomFloat(-2.0, 2.0), Utility.RandomFloat(-2.0, 2.0), Utility.RandomFloat(0.2, 1.8), Utility.RandomFloat(10, 50))
		endif
		things[stripStage] = thing
	endif
	stripStage += 1
	; bdebug.notification("stripping")
endfunction

bool function canImpregnate(actor npc)
	return !isFemale(npc)
EndFunction


function doOStim(actor actor1, actor actor2, int tags, bool aggressive = false) 
;Debug.Notification("sex")
	if actor2.IsDead(); catches certain edge cases during combat
		Return
	endif
 
	bool recog  = false

	
	spellTimer = 30	


	bool requireUndress = true
	string startingAnim = ""
	if false
		if tags == 0
			if playersuccubustrackingscriptmale.chanceRoll(50)
				startingAnim = "0MF|YHy6!My9|Ho|MishHov+00Kn"
			Else
				startingAnim = "0MF|KNy6!PUy6|Sx|DoggyLoSxHT"
			endif
		elseif tags == 1
			if playersuccubustrackingscriptmale.chanceRoll(50)
				startingAnim = "0MF|YHy6!My9|Ho|MishHov+00Kn"
			Else
				startingAnim = "0MF|KNy6!PUy6|Sx|DoggyLoSxHT"
			endif
		elseif tags == 2
			startingAnim = "0MF|Sy6!KNy9|ApPJ|KnStraApPJB"
		elseif tags == 3
			startinganim = "0MF|Sy6!KNy9|ApHJ|KnStraApHJO"
		elseif tags == 4

		endif

		if (tags == 2) || (tags == 3)
			requireUndress = false
		endif
	endif


	bool playerInvolved = (actor1 == playerref) || (actor2 == playerref)
	
	actor playerSexPartner = None
	if playerInvolved
		if actor1 == playerref
			playersexpartner = actor2
		Else
			playersexpartner = actor1
		endif
	endif

	bool PartnerKnowsTrueGenderAtStart = true
	if transPlayer && playerInvolved
		PartnerKnowsTrueGenderAtStart = GetNPCKnowsPlayerSex(playerSexPartner)
	endif


	if playerInvolved
		game.ForceThirdPerson()
	endif

	if !aggressive
		ostim.StartScene(actor1, actor2, zundressDom = requireUndress, zundressSub = requireUndress, zanimateUndress = false, zstartingAnimation = startingAnim)
	Else
		ostim.StartScene(actor1, actor2, aggressive = true, aggressingActor = actor1)
	endif
	Utility.Wait(5)
	if playerinvolved && playersuccubustrackingscriptmale.isNaked(playerref)
		
	endif
	


	while ostim.animationRunning()
		Utility.wait(1.1)

	

		if transPlayer && !PartnerKnowsTrueGenderAtStart
			Utility.wait(2)

			if GetNPCKnowsPlayerSex(playerSexPartner) ;passes when gender is revealed
				PartnerKnowsTrueGenderAtStart = true ;switch this so this doesn't run over and over

				int desire = NPCDesiresPlayerGender(playerSexPartner)

				if desire == 1
					;gets angry
					if playersuccubustrackingscriptmale.chanceRoll(50)
						debug.Notification(playerSexPartner.GetDisplayName() + " sees your cock and is infuriated")
					Else
						debug.Notification(playerSexPartner.GetDisplayName() + " sees your cock and is overcome with embarrassment")
					endif
					playerSexPartner.SetRelationshipRank(playerref, -3)
					ostim.endAnimation()

					if playersuccubustrackingscriptmale.chanceRoll(50)
						playerSexPartner.StartCombat(playerref)
					endif
				elseif desire == 4
					;stops

					if playersuccubustrackingscriptmale.chanceRoll(50)
						debug.Notification(playerSexPartner.GetDisplayName() + " sees your cock and freezes up for a moment")
					Else
						debug.Notification(playerSexPartner.GetDisplayName() + " sees your cock and is overcome with embarrassment")
					endif

					if playersuccubustrackingscriptmale.chanceRoll(50)
						playerSexPartner.SetRelationshipRank(playerref, -1)
					endif
					if playersuccubustrackingscriptmale.chanceRoll(50)
						ostim.endAnimation()
					endif
				Else
					debug.Notification(playerSexPartner.GetDisplayName() + " notices your cock")
				endif
			endif
		endif
	EndWhile

	if playerinvolved
	endif

	
endfunction

Function doSex(actor actor1, actor actor2, bool aggressive = false, bool femDom = false, int tags = -1) ;raper goes first (male goes first?)
	;Debug.Notification("sex")
	if actor2.IsDead(); catches certain edge cases during combat
		Return
	endif
	if !aggressive && useOstimForNonAggressive
		doOStim(actor1, actor2, tags)
		return
	endif
	bool recog  = false


	sslThreadModel Thread = Sexlab.NewThread()



	spellTimer = 30	

	int Actorcode = Thread.AddActor(actor2)
	if(Actorcode != 0)
		Debug.Notification("Error adding actor 2: " + Actorcode)
		return
	EndIf


	Actorcode = Thread.AddActor(actor1)
	if(Actorcode != 1)
		Debug.Notification("Error adding actor 1: " + Actorcode)
		return
	EndIf

	

	bool requireUndress = true
	if tags > -1
		Thread.SetAnimations(sexlab.GetAnimationsByTags(2, sexActs[tags],TagSuppress = "",RequireAll = true))
		if (tags == 2) || (tags == 3)
			requireUndress = false
		endif
	endif



	if !requireUndress
		thread.SetNoStripping(actor2)
	endif

	bool playerInvolved = (actor1 == playerref) || (actor2 == playerref)

	actor playerSexPartner = None
	if playerInvolved
		if actor1 == playerref
			playersexpartner = actor2
		Else
			playersexpartner = actor1
		endif
	endif

	bool PartnerKnowsTrueGenderAtStart = true
	if transPlayer && playerInvolved
		PartnerKnowsTrueGenderAtStart = GetNPCKnowsPlayerSex(playerSexPartner)
	endif

	
	if aggressive
		actor victim

		if femDom
			Thread.SetAnimations(sexlab.GetAnimationsByTags(2, "femdom,vaginal",TagSuppress = "",RequireAll = true))
			victim = actor1 ;femdom
		Else
			victim = actor2
		endif

		SuccCrimeSpell.cast(Aactor)		
		Thread.SetVictim(victim, true)
		Thread.DisableUndressAnimation(victim)
		Thread.DisableRedress(victim)
		Thread.IsAggressive = true

		

		recog = AttemptActorRecog(actor2, actor1)
		if recog
			actor2.SetRelationshipRank(actor1, -4)
		endif
	endif

	if playerInvolved
		game.ForceThirdPerson()
	endif

	Thread.StartThread()

	bool vaginal = false ;vaginal, and player is not involved.
	if !playerInvolved
		vaginal = Thread.Animation.IsVaginal
	endif


	while SexLab.IsActorActive(actor2)
		Utility.wait(0.1)

		if aggressive
			if spellTimer < 1
				SuccCrimeSpell.cast(Aactor)		
				spellTimer = 30
			Else
				spellTimer -= 1
			endif
		endif

		if transPlayer && !PartnerKnowsTrueGenderAtStart && !aggressive
			Utility.wait(2)

			if GetNPCKnowsPlayerSex(playerSexPartner) ;passes when gender is revealed
				PartnerKnowsTrueGenderAtStart = true ;switch this so this doesn't run over and over

				int desire = NPCDesiresPlayerGender(playerSexPartner)

				if desire == 1
					;gets angry
					if playersuccubustrackingscriptmale.chanceRoll(50)
						debug.Notification(playerSexPartner.GetDisplayName() + " sees your cock and is infuriated")
					Else
						debug.Notification(playerSexPartner.GetDisplayName() + " sees your cock and is overcome with embarrassment")
					endif
					playerSexPartner.SetRelationshipRank(playerref, -3)
					;thread.Stop()

					if playersuccubustrackingscriptmale.chanceRoll(50)
						playerSexPartner.StartCombat(playerref)
					endif
				elseif desire == 4
					;stops

					if playersuccubustrackingscriptmale.chanceRoll(50)
						debug.Notification(playerSexPartner.GetDisplayName() + " sees your cock and freezes up for a moment")
					Else
						debug.Notification(playerSexPartner.GetDisplayName() + " sees your cock and is overcome with embarrassment")
					endif

					if playersuccubustrackingscriptmale.chanceRoll(50)
						playerSexPartner.SetRelationshipRank(playerref, -1)
					endif
					if playersuccubustrackingscriptmale.chanceRoll(50)
						;thread.Stop()
					endif
				Else
					debug.Notification(playerSexPartner.GetDisplayName() + " notices your cock")
				endif
			endif
		endif
	EndWhile

	if playerInvolved
		game.ForceFirstPerson()
	EndIf

	if aggressive && !femDom
		

		if actor1 == playerref && (bountySet == false)
			if recog
				

				if actor2.GetCrimeFaction()
					(Succubusquest as playersuccubustrackingscriptmale).QueueRape(actor2)
				endif
			endif
		endif

		if !femdom && !isEnslaved(actor2)
			Trauma(actor2, true)
		endif

	endif

	if vaginal
		npcEjaculate(actor1, actor2)
	endif


endfunction





Function cycleDone()
	cycleCount += 10
	if playersuccubustrackingscriptmale.chanceRoll(33)
		Game.ShakeCamera(PlayerRef, afStrength = 1, afDuration = 0.3)

		
			actor damaged
			int damage

			if playersuccubustrackingscriptmale.chanceRoll(66)
				damaged = Dactor
				damage = 1

				if !PlayerAttacker
					Game.triggerscreenblood(1)
				endif

				
			Else
				damaged = Aactor
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

bool Function CanSex(actor target)
	if sexlab.IsActorActive(target)
		return false
	endif
	if target.GetRace().HasKeywordString("ActorTypeNPC")
		return true
	else
		return false
	endif


endfunction

bool function isHeadConcealed(actor target)
	return (target.GetWornForm(0x00000001) as Armor) as bool || (target.GetWornForm(0x00004000) as Armor) as bool
endfunction

bool function AttemptActorRecog(actor viewer, actor viewed)
	int rank = viewer.GetRelationShipRank(viewed)


	if !isHeadConcealed(viewed)
		return true
	endif


	if rank == 0
			return false
	elseif rank == 1
		return playersuccubustrackingscriptmale.chanceRoll(30)
	elseif rank == 2
		return playersuccubustrackingscriptmale.chanceRoll(60)
	elseif rank == -4
		return True
	elseif rank < 0
		return playersuccubustrackingscriptmale.chanceRoll(30)
	else
		return true
	endif
		

endfunction


function OnSeePlayerNaked(actor npc)
	console("Player spotted")

	if transPlayer
		if !GetNPCKnowsPlayerSex(npc)
			SetNPCKnowsPlayerSex(npc, true)
		endif
	endif

endfunction




Bool Function Trauma(Actor Target,  Bool Enter = True) 

	if target.IsDead() 
		Return  false
	endif
	if Target == playerref
		return false
	endif

	If Enter
			if isEnslaved(target)
				Return False
			endif
			Calm(Target)
;			StayStill(Target)
;			Target.SetRestrained()
;			Target.SetDontMove()
			
			;StateDuration = Duration
			;Target.addspell(SuccubusTraumaSpell)

			if !Target.HasMagicEffect(succubusTraumaSpell.GetNthEffectMagicEffect(0))		
				SuccubusTraumaSpell.cast(Target)
			endif
				;Perpetrator = Aggressor
			;SetStringValue(Target, "DefeatState", "Trauma")
			;SetStringValue(Target, "DefeatType", Type)
			;SetStringValue(Target, "DefeatStateAnim", "IdleWounded_03")
			;Target.AddSpell(TraumaSPL)
			;Target.SetPlayerTeammate(true)
			Target.EvaluatePackage()
			Debug.SendAnimationEvent(Target, "IdleWounded_02")
			Utility.wait(1)



;				If (i == 0)
;					SetStringValue(Target, "DefeatStateAnim", "DefeatEstrusTrauma")
;					SendAnimationEvent(Target, "DefeatEstrusTrauma")
				
			;		SetStringValue(Target, "DefeatStateAnim", "IdleWounded_02")

			
			int Tries = 3
			float X
			float newX

			X = Target.X

			while Tries != 0
				Utility.wait(1)

				newX = Target.X

				if newX == X
					Tries = 0
				Else
					;debug.Notification("Trauma failed")
					Debug.SendAnimationEvent(Target, "IdleWounded_02")
					X = newX
					tries -= 1
				endif
					
			endwhile

		

			Return True
		
	Else
		;If Target.HasSpell(TraumaSPL)
			;UnsetStringValue(Target, "DefeatStateAnim")
		;	If UnCalm
				;target.SetPlayerTeammate(false, false)

				Debug.SendAnimationEvent(Target, "DefeatTraumaExit")
				Calm(Target, Enter = False)
		;	Endif
;			StayStill(Target, False)
;			Target.SetRestrained(False)
;			Target.SetDontMove(False)
			;UnsetStringValue(Target, "DefeatState")
			;UnSetStringValue(Target, "DefeatType")
		;	Target.RemoveSpell(TraumaSPL)
			Return True
		;Endif
	Endif
	Return False
EndFunction

Bool Function Calm(Actor Target, Bool StayPut = True, Bool Enter = True) 
	If Enter
		If !Target.IsInFaction(CalmFaction)
			;Target.AddSpell(TrueCalmSPL)
			Target.AddToFaction(CalmFaction)
			Target.StopCombat()
			Target.StopCombatAlarm()
			If StayPut
				ActorUtil.AddPackageOverride(Target, DoNothing, 100, 1)
				Target.EvaluatePackage()
				;target.SetDontMove(true)
			Endif
			Return True
		Else
			Target.StopCombatAlarm()
		Endif
	Else
		;If Target.HasSpell(TrueCalmSPL)
			Target.RemoveFromFaction(CalmFaction)
			;target.SetDontMove(false)
			If StayPut
				ActorUtil.RemovePackageOverride(Target, DoNothing)
				Target.EvaluatePackage()
			Endif
			;Target.RemoveSpell(TrueCalmSPL)
			Return True
		;Endif
	Endif
	Return False
EndFunction



Function PickUpThings(actor target, ObjectReference[] items)
	int i = 0

	if target.IsDead() || isEnslaved(target)
		Return
	endif

	while i < items.Length
		
		if items[i]
			if playerref.GetItemCount(items[i]) < 1

				target.additem(items[i])

				target.EquipItem(items[i].GetBaseObject())
			endif
		EndIf

		i += 1
	endwhile
EndFunction

Function AttemptReportRape(actor guard)
		

	;if Aactor != playerref
	;	Return
	;EndIf

	if !bountySet
		bountyset = true
		AddBounty(800, guard.GetCrimeFaction())	
	endif

EndFunction

Function AttemptReportNudity(actor guard)
	
	float time = Utility.GetCurrentGameTime()

	if ( time - lastNudityReport) > 0.25
		AddBounty(80, guard.GetCrimeFaction(), violent = false)	
		lastNudityReport = time
	endif
	

EndFunction

Function AddBounty(int amount, Faction crimeFaction, bool silent = false, bool violent = true)


	crimeFaction.ModCrimeGold(amount, violent)


	if !silent
		Debug.Notification(amount + " bounty added to " + crimeFaction.GetName())
	endif

EndFunction



function saveNPCData(actor npc) 
	
	if !SuccubusProcessedNPCs.HasForm(npc as form)
		SuccubusProcessedNPCs.AddForm(npc as form)
	endif
EndFunction

function wipeData(int wipemode) ; 0 - dead/disabled npc | 1 - dead/disabled and non-unique npcs | 2 - all npcs
	Int iIndex = SuccubusProcessedNPCs.GetSize() ; Indices are offset by 1 relative to size
	int clearCount = 0
		While iIndex
			iIndex -= 1
			bool clear = false
			actor npc = SuccubusProcessedNPCs.GetAt(iIndex) As actor ; Note that you must typecast the entry from the formlist using 'As'.
		
			if wipemode == 0
				clear = (npc.IsDead() || npc.IsDisabled() || npc.IsDeleted())
			elseif wipemode == 1
				clear = (npc.IsDead() || npc.IsDisabled() || npc.IsDeleted() || (!npc.GetActorBase().IsUnique()))
			elseif wipemode == 2
				clear = True
			EndIf

			if clear
				if !npc.IsInFaction(SuccubusProcessed)
					clear = false
				endif
			endif
			if clear
				clearNPCOverrides(npc)
				clearCount += 1
			endif
		EndWhile

		
		console("Cleared data of " + clearCount + " npcs.")
endfunction

function clearNPCOverrides(actor npc)
	NiOverride.RemoveAllReferenceNodeOverrides(npc); pubes, etc
	NiOverride.ClearMorphs(npc) ; bodygen?



	npc.RemoveFromFaction(succubusprocessed)
	;SuccubusProcessedNPCs.RemoveAddedForm(npc as form)
EndFunction

function openDataMenu()
	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int exit = 7
	Int size = 1
	Int all = 5
	Int dead = 2
	Int nonunique = 3

	wheelMenu.SetPropertyIndexString("optionLabelText", exit, "Cancel")
	wheelMenu.SetPropertyIndexString("optionLabelText", size, "Show processed list size")
	wheelMenu.SetPropertyIndexString("optionLabelText", all, "all bodygen")
	wheelMenu.SetPropertyIndexString("optionLabelText", dead, "dead")
	wheelMenu.SetPropertyIndexString("optionLabelText", nonunique, "nonunique and dead")

	wheelMenu.SetPropertyIndexBool("optionEnabled", exit, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", size, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", all, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", dead, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", nonunique, true)

	int ret = wheelMenu.OpenMenu()

	if ret == size
		debug.messagebox(SuccubusProcessedNPCs.getsize())
	elseif ret == nonunique
		wipeData(1)
	elseif ret == all
		wipeData(2)
	elseif ret == dead
		wipeData(0)
	Else
		return
	endif
EndFunction

int function openSexActMenu(actor act)
	UIMenuBase wheelMenu = UIExtensions.GetMenu("UIWheelMenu")
	Int exit = 7
	Int vaginal = 1
	Int anal = 5
	Int oral = 2
	Int handjob = 3
	Int boobjob = 4

	wheelMenu.SetPropertyIndexString("optionLabelText", exit, "Cancel")
	
	wheelMenu.SetPropertyIndexString("optionLabelText", anal, "ANAL")
	wheelMenu.SetPropertyIndexString("optionLabelText", oral, "ORAL")
	wheelMenu.SetPropertyIndexString("optionLabelText", handjob, "HANDJOB")
	

	wheelMenu.SetPropertyIndexBool("optionEnabled", exit, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", anal, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", oral, true)
	wheelMenu.SetPropertyIndexBool("optionEnabled", handjob, true)
	if appearsFemale(act)
		wheelMenu.SetPropertyIndexString("optionLabelText", boobjob, "BOOBJOB")
		wheelMenu.SetPropertyIndexBool("optionEnabled", boobjob, true)
	endif
	if isFemale(act)
		wheelMenu.SetPropertyIndexString("optionLabelText", vaginal, "VAGINAL")
		wheelMenu.SetPropertyIndexBool("optionEnabled", vaginal, true)
	endif

	int ret = wheelMenu.OpenMenu(act)

	if ret == vaginal
		return 0
	elseif ret == anal
		return 1
	elseif ret == oral
		return 2
	elseif ret == handjob
		return 3
	elseif ret == boobjob
		return 4
	Else
		return -1
	endif
EndFunction

; 1 hates
; 2 desires | this gives a sexual value bonus
; 3 will have sex but does not desire, no sexual value bonus
; 4 will not have sex
int function NPCDesiresPlayerGender(actor npc)
	int ret
	int playerGender 
	;the above gender should be set to what the NPC knows
	;1 - male
	;2 - female
	;3 - trans | female body
	;4 - trans | male body

	if transPlayer
		if GetNPCKnowsPlayerSex(npc) ; the secret is out
			if appearsFemale(playerref)
				playerGender = 3
			Else
				playerGender = 4
			endif
		Else
			if appearsFemale(playerref)
				playergender = 2
			Else
				playerGender = 1
			endif
		endif
	else
		if appearsFemale(playerref)
			playergender = 2
		Else
			playerGender = 1
		endif
	endif

	bool femaleNPC = appearsFemale(npc)
	int gayness = GetGayness(npc)

	if femaleNPC

		if playergender == 1 ;straight
			if gayness < 5
				ret = 3
			elseif gayness == 7
				ret = 1
			Else
				ret = 4
			endif
		elseif playergender == 2 ;lesbian
			if gayness == 1
				ret = 1
			elseif gayness < 4
				ret = 4
			elseif gayness == 4 ; pan
				ret = 3
			else ;explicitly gay
				ret = 2 
			endif

		elseif playergender == 3 ;woman with trap
			if (gayness == 1) || (gayness == 7)
				ret = 1
			elseif (gayness == 2) || (gayness == 6) || (gayness == 3)
				ret = 4
			elseif (gayness == 4)
				ret = 2
			Else
				ret = 3
			endif
		else ;woman with man with vag
			if (gayness == 1) || (gayness == 7)
				ret = 1
			elseif (gayness == 2) || (gayness == 6) || (gayness == 5)
				ret = 4
			elseif (gayness == 4)
				ret = 2
			Else
				ret = 3
			endif
		endif

	else ;males
		if playergender == 2 ;straight
			if gayness < 5
				ret = 2
			elseif gayness == 7
				ret = 1
			Else
				ret = 4
			endif
		elseif playergender == 1 ;gay
			if gayness == 1
				ret = 1
			elseif gayness < 4
				ret = 4
			elseif gayness == 4 ; pan
				ret = 2
			else ;explicitly gay
				ret = 2 
			endif
		elseif playergender == 3 ;man with trap
			if (gayness == 1) || (gayness == 7)
				ret = 1
			elseif (gayness == 2) || (gayness == 6) || (gayness == 5)
				ret = 4 
			elseif (gayness == 4)
				ret = 2
			Else
				ret = 2
			endif
		else ;man with man with vag
			if (gayness == 1) || (gayness == 7)
				ret = 1
			elseif (gayness == 2) || (gayness == 6) || (gayness == 3)
				ret = 4
			elseif (gayness == 4)
				ret = 2
			Else
				ret = 2
			endif
		endif

	endif
	
	console("Desire value: " + ret + " NPC gayness: " + gayness + "Player gender: " + playerGender)


	return ret

endfunction

int function GetGayness(actor npc)
; 1 - homophobic
; 2 - Straight, Has sex with other sex only
; 3 - mostly Straight, Has sex with other sex and trans that match other sex's appearance
; 4 - pansexual, sex with all
; 5 - mostly gay/lesbian, only has sex with same gender and trans that match their sex's appearance
; 6 - gay/lesbian, has sex with same sex only
; 7 - heterophobic

	int gayness = GetNPCDataInt(npc, "gayness")

	if gayness < 1
		setGayness(npc)
		gayness = GetNPCDataInt(npc, "gayness")
	endif

	return gayness
	

endfunction

function setGayness(actor npc)
	int num = Utility.RandomInt(1, 100)
	int gay = -1

	if !appearsFemale(npc)
		if num < 5
			gay = 1
		elseif num < 86
			gay = 2
		elseif num < 94
			gay = 3
		elseif num < 95
			gay = 4
		elseif num < 98
			gay = 5
		elseif num < 100
			gay = 6
		elseif num < 101
			gay = 7
		endif
	Else ;females
		if num < 2
			gay = 1
		elseif num < 80
			gay = 2
		elseif num < 94
			gay = 3
		elseif num < 96
			gay = 4
		elseif num < 98
			gay = 5
		elseif num < 100
			gay = 6
		elseif num < 101
			gay = 7
		endif
	endif

	StoreNPCDataInt(npc, "gayness", gay)
endfunction
function SetNPCLastProstTime(actor npc) ;sets to current time
	StoreNPCDataFloat(npc, "LastSexBuyTime", Utility.GetCurrentGameTime())
EndFunction

float function GetNPCLastProstTime(actor npc)
	return GetNPCDataFloat(npc, "LastSexBuyTime")
EndFunction

function SetNPCKnowsPlayerSex(actor npc, bool knows) ;for trans/futa characters only.
	int num
	if knows
		num = 1
	Else
		num = 0
	endif
	StoreNPCDataInt(npc, "KnowsPlayerGender", num)
endfunction

bool function GetNPCKnowsPlayerSex(actor npc)
	if GetNPCDataInt(npc, "KnowsPlayerGender") < 1
		return False
	else
		return true
	endif
endfunction

function console(string in) global
	;MiscUtil.PrintConsole("-----------------------------")
	;MiscUtil.PrintConsole("DS: " + in)
	;MiscUtil.PrintConsole("-----------------------------")
EndFunction

function StoreNPCDataFloat(actor npc, string keys, float num)
	StorageUtil.SetFloatValue(npc as form, keys, num)
	console("Set value " + num + " for key " + keys)
EndFunction

float function GetNPCDataFloat(actor npc, string keys)
	return StorageUtil.GetFloatValue(npc, keys, -1)
EndFunction

function StoreNPCDataInt(actor npc, string keys, int num)
	StorageUtil.SetIntValue(npc as form, keys, num)
	console("Set value " + num + " for key " + keys)
EndFunction

int function GetNPCDataInt(actor npc, string keys)
	return StorageUtil.GetIntValue(npc, keys, -1)
EndFunction

;bugs

;enemies have idle dialogue when trauma'd
;enemies can sometimes fall through the ground after a trauma duel is lost and they are impulsed
;occasionally the armor piece is not ripped off during a duel

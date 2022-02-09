ScriptName ODefeatPlayer Extends ReferenceAlias
import outils 

actor property playerref auto
ODefeatMain property odefeat auto
race property OldPeopleRace auto

bool Property EnableVictim Auto ; do not modify directly

Event OnInit()
	playerref = game.GetPlayer()
	odefeat = odefeatmain.GetODefeat()

	OnPlayerLoadGame()
EndEvent

Event OnPlayerLoadGame()
	if EnableVictim
		RegisterForSingleUpdate(5.0)
		RegisterForAnimationEvent(playerref, "JumpLandEnd")
	endif 
EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	if !EnableVictim
		return 
	endif

	if playerref.IsInKillMove()
		playerref.DamageAV("health", 30.0)
	endif 

	CheckPlayerStatus()
EndEvent

Event OnUpdate()
	CheckPlayerStatus()

	if EnableVictim
		RegisterForSingleUpdate(1.0)
	endif 
EndEvent


Function CheckPlayerStatus()
	float healthPercent = playerref.GetActorValuePercentage("health")
	
	if (healthPercent < 0.0) && OSANative.TryLock("mtx_od_deathhandle")
		Writelog("Player is dead")

		HandlePlayerDeath()

		osanative.Unlock("mtx_od_deathhandle")
	endif 
EndFunction

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	if !EnableVictim
		return 
	endif

	if asEventName == "JumpLandEnd"
		float healthPercent = playerref.GetActorValuePercentage("health")
		if (healthPercent < 0.0)
			ODefeatMain.KillPlayer()
			Writelog("Player died from falling...")

		endif 
	endif 
EndEvent

Function HandlePlayerDeath()
	actor[] enemies = osanative.sortactorsbydistance(playerref, PO3_SKSEFunctions.GetCombatTargets(playerref))
	writelog(enemies.Length);
	if (enemies.Length < 1)
		ODefeatMain.KillPlayer()
		Writelog("No enemies...")
	endif 

	if (ChanceRoll(odefeat.DefeatedAssaultChance))
		if odefeat.MaleNPCsWontAssault
			enemies = OSANative.RemoveActorsWithGender(enemies, 0)
		endif 
		if odefeat.FemaleNPCsWontAssault
			enemies = OSANative.RemoveActorsWithGender(enemies, 1)
		endif
		int i = 0
		int max = enemies.Length
		while i < max 
			actor enemy = enemies[i]
			if (enemy.getav("morality") <= odefeat.MoralityToAssault)
				if odefeat.isValidAttackTarget(enemy)
					if (!odefeat.AllowOldPeopleRace && enemy.getRace() == OldPeopleRace)
						;nothing
					else
						if !odefeat.EnableStruggle 
							odefeat.PlayerDefenseFailedEvent(enemy)
							return
						else
							odefeat.attemptAttack(enemy, playerref)
							return
						endif
					endif
				endif 
			endif 

			i += 1
		EndWhile

		ODefeatMain.KillPlayer()
		Writelog("All enemies invalid, killing player")
	else 
		ODefeatMain.KillPlayer()
		Writelog("No valid scene could be created, killing player as fallback.")
	endif 
EndFunction

Function KnockdownAnimation()
	if IsInFirstPerson()
		debug.SendAnimationEvent(playerref, "TG05_KnockOut")
	else 
		debug.SendAnimationEvent(playerref, "bleedOutStart")
	endif 
endfunction

; This just makes life easier sometimes.
Function WriteLog(String OutputLog, bool error = false)
    MiscUtil.PrintConsole("ODefeat: " + OutputLog)
    Debug.Trace("ODefeat: " + OutputLog)
    if (error == true)
        Debug.Notification("ODefeat: " + OutputLog)
    endIF
EndFunction
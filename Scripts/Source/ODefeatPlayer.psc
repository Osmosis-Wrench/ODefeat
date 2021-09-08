ScriptName ODefeatPlayer Extends ReferenceAlias
import outils 

actor playerref 
ODefeatMain odefeat

bool Property EnableVictim Auto ; do not modify directly
Event OnInit()
	playerref = game.GetPlayer()
	odefeat = odefeatmain.GetODefeat()

	OnPlayerLoadGame()
EndEvent

Event OnPlayerLoadGame()
	RegisterForAnimationEvent(playerref, "JumpLandEnd")
EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	if !EnableVictim
		return 
	endif
	
	if playerref.IsInKillMove()
		playerref.DamageAV("health", 30.0)
	endif 

	float healthPercent = playerref.GetActorValuePercentage("health")
	

	if (healthPercent < 0.0) && OSANative.TryLock("mtx_od_deathhandle")
		Console("Player is dead")

		HandlePlayerDeath()
		 

		osanative.Unlock("mtx_od_deathhandle")
	endif 
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	if !EnableVictim
		return 
	endif

	if asEventName == "JumpLandEnd"
		float healthPercent = playerref.GetActorValuePercentage("health")
		if (healthPercent < 0.0)
			ODefeatMain.KillPlayer()
			Console("Player died from falling...")

		endif 
	endif 
EndEvent

Function HandlePlayerDeath()
	actor[] enemies = osanative.sortactorsbydistance(playerref, PO3_SKSEFunctions.GetCombatTargets(playerref))
	if enemies.Length < 1
		ODefeatMain.KillPlayer()
		Console("No enemies...")
	endif 


	if ChanceRoll(odefeat.DefeatedAssaultChance)
		
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
			if (enemy.getav("morality") < 1)
				if odefeat.isValidAttackTarget(enemy)
					odefeat.attemptAttack(enemy, playerref)

					return 
				endif 
			endif 

			i += 1
		EndWhile


		ODefeatMain.KillPlayer()
		Console("All enemies invalid, killing player")


	else 
		ODefeatMain.KillPlayer()
		Console("Rolled player death")
	endif 
EndFunction

Function KnockdownAnimation()
	if IsInFirstPerson()
		debug.SendAnimationEvent(playerref, "TG05_KnockOut")
	else 
		debug.SendAnimationEvent(playerref, "bleedOutStart")
	endif 
endfunction
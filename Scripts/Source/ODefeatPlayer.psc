ScriptName ODefeatPlayer Extends ReferenceAlias
import outils 

bool pause
actor playerref 
ODefeatMain odefeat

bool Property EnableVictim Auto ; do not modify directly
Event OnInit()
	pause = false
	playerref = game.GetPlayer()
	odefeat = odefeatmain.GetODefeat()
EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	if pause || !EnableVictim
		return 
	endif
	
	float healthPercent = playerref.GetActorValuePercentage("health")
	if playerref.IsInKillMove()
		healthPercent = -0.5
	endif 

	if (healthPercent < 0.0) && !pause
		pause = true 
		Console("Player is dead")

		HandlePlayerDeath()

		pause = false
	endif 
EndEvent

Function HandlePlayerDeath()
	actor[] enemies = PO3_SKSEFunctions.GetCombatTargets(playerref)
	if enemies.Length < 1
		ODefeatMain.KillPlayer()
		Console("No enemies...")
	endif 


	if ChanceRoll(odefeat.DefeatedAssaultChance)
		; try to assault player

		; TODO sort by distance
		; TODO gender settings?

		;KnockdownAnimation()

		;bool femalePlayer = AppearsFemale(playerref)

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

	else 
		ODefeatMain.KillPlayer()
	endif 
EndFunction

Function KnockdownAnimation()
	if IsInFirstPerson()
		debug.SendAnimationEvent(playerref, "TG05_KnockOut")
	else 
		debug.SendAnimationEvent(playerref, "bleedOutStart")
	endif 
endfunction
Scriptname ODefeatEffectCollapse extends ActiveMagicEffect  

Float Property PercentHealth = 100.0 Auto  

Quest property ODefeat auto 

Actor Property PlayerRef  Auto  

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked )
    PercentHealth = PlayerRef.GetAVPercentage("Health")
    If (PercentHealth <= 0.1 && PercentHealth != 0.0)
        (ODefeat as ODefeatMain).Writelog("Going Down.")
        (ODefeat as ODefeatMain).attemptAttack(akAggressor as Actor, PlayerRef)
        ; Multiple attack attemps running at the same time are handled in attempAttack already.
    EndIf
endEvent
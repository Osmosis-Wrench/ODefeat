Scriptname ODefeatEffect extends activemagiceffect  


ObjectReference[] equipment

Quest property ODefeat auto 

Event OnEffectStart(Actor akTarget, Actor akCaster)
	debug.MessageBox("Effect started (remove this)")
	;equipment = (ODefeat as ODefeatMain).Things
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	
	
	(ODefeat as ODefeatMain).DoTrauma(akTarget, false)
	
	Utility.wait(3)

	;(PlayerSuccubusTrackingQuestMale as SLGMainQuestScript).PickUpThings(akTarget, equipment)
	
EndEvent
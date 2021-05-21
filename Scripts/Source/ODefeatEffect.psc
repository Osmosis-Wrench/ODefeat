Scriptname ODefeatEffect extends activemagiceffect  


ObjectReference[] equipment

Quest property ODefeat auto 

Event OnEffectStart(Actor akTarget, Actor akCaster)
	equipment = (ODefeat as ODefeatMain).droppedItems
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	
	
	(ODefeat as ODefeatMain).DoTrauma(akTarget, false)
	
	Utility.wait(3)

	(ODefeat as ODefeatMain).ostim.GetUndressScript().PickUpThings(akTarget, equipment)

	
EndEvent
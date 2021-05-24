Scriptname ODefeatEffect extends activemagiceffect  


ObjectReference[] equipment

Quest property ODefeat auto 

Event OnEffectStart(Actor akTarget, Actor akCaster)
	equipment = (ODefeat as ODefeatMain).droppedItems
	RegisterForModEvent("ostim_end", "OstimEnd")
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	
	
	(ODefeat as ODefeatMain).DoTrauma(akTarget, false)
	
	Utility.wait(3)

	(ODefeat as ODefeatMain).ostim.GetUndressScript().PickUpThings(akTarget, equipment)

	
EndEvent

Event OStimEnd(string eventName, string strArg, float numArg, Form sender)
    (ODefeat as ODefeatMain).doTrauma(GetTargetActor())
EndEvent 
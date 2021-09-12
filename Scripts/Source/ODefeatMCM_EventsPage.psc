Scriptname ODefeatMCM_EventsPage extends nl_mcm_module

ODefeatMain property main auto

String Blue = "#6699ff"
String Pink = "#ff3389"

int property oDefeatEventsJDB
    int function get()
        return JDB.solveObj(".ODefeat.events")
    EndFunction
    function set(int object)
        JDB.solveObjSetter(".ODefeat.events", object, true)
    endfunction
endproperty

event OnInit()
    RegisterModule("Events Options", 2)
endEvent

Event OnPageInit()
    BuildDatabase()
EndEvent

Event OnPageDraw()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddTextOptionST("info_state", "Information", "Click")
    AddHeaderOption(FONT_CUSTOM("Event Controls:", Blue))
    AddTextOptionST("rebuild_database_state", "Rebuild Database", "Click")

    AddHeaderOption(FONT_CUSTOM("Built-in Defeat Event Probabilities", pink))
    AddSliderOptionST("DefeatedAssaultChance_State", "Assault Chance", main.DefeatedAssaultChance) ; move to main as well?
    ;AddSliderOptionST("DefeatedSkipChance_State", "Skip Assault Chance", main.DefeatedSkipChance) 
    ;todo make this ^ do something in main or player
    AddSliderOptionST("MinValueToRob_State", "Minimum value to steal", main.MinValueToRob)
    AddSliderOptionST("RobberyItemStealChance_State", "Item theft chance", main.RobberyItemStealChance)
    
    SetCursorPosition(1)
    AddHeaderOption(FONT_CUSTOM("Post-defeat Events:", Blue))
    BuildPageContents()
EndEvent

function BuildPageContents()
    string eventkey = JMap.NextKey(oDefeatEventsJDB)
    while eventkey
        int eventWeighting = Jvalue.SolveInt(oDefeatEventsJDB, "." + eventkey + ".Weighting")
        AddSliderOptionST("event_slider_state___" + eventkey, eventkey, eventWeighting)
        eventkey = Jmap.nextKey(oDefeatEventsJDB, eventkey)
    endwhile
endFunction

state info_state
    event OnSelectST(string state_id)
        debug.messagebox("These are modular events that occur after losing a player-victim struggle" + \
            "\n\nThey will occur after the sex scene, if a sex scene takes place (the chance of a sex scene is configurable), or right after losing to your enemies if no OStim scene occurs" + \
            "\n\nThe right numbers are the weights of it occuring, if event B has a weight of 20 and event A has a weight of 1 and we run 21 victim scenes, A will be selected on average 1 of the 20. 0 is disabled." + \
            "\n\nThis page does nothing if player victim is disabled" + \
            "\n\nMod authors can add new events to this page")
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("Click for information about this page")
    endevent
endState

state rebuild_database_state
    event OnSelectST(string state_id)
        BuildDatabase()
        ForcePageReset()
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("Rebuilds the event database. \n This will purge invalid events, load new events and reset weighting to default.")
    endevent
endState

State event_slider_state
    event OnSliderOpenST(string state_id)
        int i = Jvalue.SolveInt(oDefeatEventsJDB, "."+state_id+".Weighting")
        SetSliderDialog(i, 0, 100, 1.0, 50)
    endevent

    event OnSliderAcceptST(string state_id, float f)
        JValue.SolveIntSetter(oDefeatEventsJDB, "." + state_id + ".Weighting", f as int)
        SetSliderOptionValueST(f)
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("Set the chance for " + state_id +" \n Description: "+ JValue.SolveStr(oDefeatEventsJDB, "."+state_id+".Description"))
    endevent
EndState

Function BuildDatabase()
    int eventFilelist = JValue.readFromDirectory("Data/meshes/ODefeatData/events", ".json")
    JValue.Retain(eventFilelist) 
    ; the retain and release are probably unnessesary, but just in case somebody wants to load like 100+ events this should still be fine.
    int eventData
    string eventFileKey = Jmap.NextKey(eventFilelist)
    while eventFileKey
        eventData = Jmap.GetObj(eventFilelist, eventFileKey)
        string eventKey = Jmap.NextKey(eventData)
        while eventKey
            int obj = JValue.SolveObj(eventData, "." + eventKey)
            form formvalue = JValue.SolveForm(obj, ".Form")
            if (!oDefeatEventsJDB && (formvalue == true))
                int firstObj = jmap.object()
                Jmap.SetObj(firstObj, eventKey, obj)
                oDefeatEventsJDB = firstObj
            elseif (formvalue == true)
                JMap.SetObj(oDefeatEventsJDB, eventKey, obj)
            endif
            eventKey = Jmap.NextKey(eventData, eventKey)
        endwhile
        eventFileKey = Jmap.NextKey(eventFilelist, eventFileKey)
    endwhile
    JValue.Release(eventFilelist)
EndFunction

state DefeatedAssaultChance_State
	event OnDefaultST(string state_id)
		main.DefeatedAssaultChance = 100
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("The chance you will be assaulted after dying with valid enemies nearby.")
	endevent
	
	event OnSliderOpenST(string state_id)
		SetSliderDialog(main.DefeatedAssaultChance, 0, 100, 1.0, 100)
	endevent
	
	event OnSliderAcceptST(string state_id, float f)
		main.DefeatedAssaultChance = f as int
		SetSliderOptionValueST(f)
	endevent
endstate

state DefeatedSkipChance_State
	event OnDefaultST(string state_id)
		main.DefeatedSkipChance = 0
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("The chance that after dying you'll get a post death event, without being assaulted.")
	endevent
	
	event OnSliderOpenST(string state_id)
		SetSliderDialog(main.DefeatedSkipChance, 0, 100, 1.0, 0)
	endevent
	
	event OnSliderAcceptST(string state_id, float f)
		main.DefeatedSkipChance = f as int
		SetSliderOptionValueST(f)
	endevent
endstate

state MinValueToRob_State
	event OnDefaultST(string state_id)
		main.MinValueToRob = 350
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("During a robbery event, items over this value may be stolen")
	endevent
	
	event OnSliderOpenST(string state_id)
		SetSliderDialog(main.MinValueToRob, 0, 2500, 10.0, 350)
	endevent
	
	event OnSliderAcceptST(string state_id, float f)
		main.MinValueToRob = f as int
		SetSliderOptionValueST(f)
	endevent
endstate

state RobberyItemStealChance_State
	event OnDefaultST(string state_id)
		main.RobberyItemStealChance = 50
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("Chance any valid individual item will be stolen during a robbery event, rolled for every valid item.")
	endevent
	
	event OnSliderOpenST(string state_id)
		SetSliderDialog(main.RobberyItemStealChance, 0, 100, 1.0, 50)
	endevent
	
	event OnSliderAcceptST(string state_id, float f)
		main.RobberyItemStealChance = f as int
		SetSliderOptionValueST(f)
	endevent
endstate

; This just makes life easier sometimes.
Function WriteLog(String OutputLog, bool error = false)
    MiscUtil.PrintConsole("ODefeat: " + OutputLog)
    Debug.Trace("ODefeat: " + OutputLog)
    if (error == true)
        Debug.Notification("ODefeat: " + OutputLog)
    endIF
EndFunction
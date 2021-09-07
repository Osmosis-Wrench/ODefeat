Scriptname ODefeatMCM_EventsPage extends nl_mcm_module

ODefeatMain property ODMain auto
bool changedDatabase
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
    OnStart()
EndEvent

Function OnStart()
    BuildDatabase()
    Utility.Wait(1) ; If this wait isn't here, the database doesn't populate until after entering and exiting the MCM. No fucking clue why lol.
    UpdateDatabase()
endFunction

Event OnPageDraw()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption(FONT_CUSTOM("After Death Events:", pink))
    JValue.WriteToFile(oDefeatEventsJDB, JContainers.UserDirectory() + "odefJDB.json")
    BuildPageContents()
EndEvent

Event OnConfigClose()
    if changedDatabase
        UpdateDatabase()
    endif
endEvent

function UpdateDatabase()
    ODMain.UpdateEventData()
    changedDatabase = false
endFunction

function BuildPageContents()
    string eventkey = JMap.NextKey(oDefeatEventsJDB)
    while eventkey
        int eventWeighting = Jvalue.SolveInt(oDefeatEventsJDB, "." + eventkey + ".Weighting")
        AddSliderOptionST("event_slider_state___" + eventkey, eventkey, eventWeighting)
        eventkey = Jmap.nextKey(oDefeatEventsJDB, eventkey)
    endwhile
endFunction

State event_slider_state
    event OnSliderOpenST(string state_id)
        int i = Jvalue.SolveInt(oDefeatEventsJDB, "."+state_id+".Weighting")
        SetSliderDialog(i, 0, 100, 1.0, 50)
    endevent

    event OnSliderAcceptST(string state_id, float f)
        JValue.SolveIntSetter(oDefeatEventsJDB, "." + state_id + ".Weighting", f as int)
        changedDatabase = true
        SetSliderOptionValueST(f)
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("Set the chance for " + state_id)
    endevent
EndState

Function BuildDatabase()
    int eventFilelist = JValue.readFromDirectory("Data/ODefeatData/", ".json")
    JValue.Retain(eventFilelist)
    int eventData
    string eventFileKey = Jmap.NextKey(eventFilelist)
    while eventFileKey
        eventData = Jmap.GetObj(eventFilelist, eventFileKey)
        string eventKey = Jmap.NextKey(eventData)
        while eventKey
            int obj = JValue.SolveObj(eventData, "." + eventKey)
            form formvalue = JValue.SolveForm(obj, ".Form")
            writelog("formvalue "+(formvalue == true))
            JValue.WriteToFile(obj, JContainers.UserDirectory() + eventKey+".json")
            if (!oDefeatEventsJDB && (formvalue == true))
                int firstObj = jmap.object()
                Jmap.SetObj(firstObj, eventKey, obj)
                oDefeatEventsJDB = firstObj
            else
                JMap.SetObj(oDefeatEventsJDB, eventKey, obj)
            endif
            eventKey = Jmap.NextKey(eventData, eventKey)
        endwhile
        eventFileKey = Jmap.NextKey(eventFilelist, eventFileKey)
    endwhile
    JValue.Release(eventFilelist)
EndFunction

; This just makes life easier sometimes.
Function WriteLog(String OutputLog, bool error = false)
    MiscUtil.PrintConsole("ODefeat: " + OutputLog)
    Debug.Trace("ODefeat: " + OutputLog)
    if (error == true)
        Debug.Notification("ODefeat: " + OutputLog)
    endIF
EndFunction
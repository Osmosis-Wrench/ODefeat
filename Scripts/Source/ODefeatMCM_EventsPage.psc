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
    ODMain.UpdateEventData()
    changedDatabase = false
endFunction

Event OnPageDraw()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption(FONT_CUSTOM("After Death Events:", pink))
    JValue.WriteToFile(oDefeatEventsJDB, JContainers.UserDirectory() + "odefJDB.json")
    BuildPageContents()
EndEvent

Event OnConfigClose()
    if changedDatabase
        ODMain.UpdateEventData()
        changedDatabase = False
    endif
endEvent

function BuildPageContents()
    string eventkey = JMap.NextKey(oDefeatEventsJDB)
    while eventkey
        bool eventEnabled = Jvalue.SolveInt(oDefeatEventsJDB, "." + eventkey + ".Enabled") as bool
        AddToggleOptionST("event_toggle_state___" + eventkey, eventkey, eventEnabled)
        eventkey = Jmap.nextKey(oDefeatEventsJDB, eventkey)
    endwhile
endFunction

State event_toggle_state
    event OnSelectST(string state_id)
        bool eventEnabled = Jvalue.SolveInt(oDefeatEventsJDB, "." + state_id + ".Enabled") as bool
        eventEnabled = !eventEnabled
        JValue.SolveIntSetter(oDefeatEventsJDB, "." + state_id + ".Enabled", eventEnabled as int)
        SetToggleOptionValueST(eventEnabled, false, "event_toggle_state___" + state_id)
        changedDatabase = true
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("Enable or Disable " + state_id)
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
            JValue.WriteToFile(obj, JContainers.UserDirectory() + eventKey+".json")
            if (!oDefeatEventsJDB)
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
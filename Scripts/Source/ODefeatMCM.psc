Scriptname ODefeatMCM extends nl_mcm_module  

ODefeatMain property main auto

; dev stuff
bool release = false
String Blue = "#6699ff"
String Pink = "#ff3389"

Event OnInit()
    RegisterModule("Core Options")
endEvent

Event OnPageInit()
    SetModName("ODefeat")
    SetLandingPage("Core Options")    
endEvent

Event OnUpdate()
    main.setdefaultsettings()
EndEvent

event OnPageDraw()
    SetCursorFillMode(TOP_TO_BOTTOM)

    AddHeaderOption(FONT_CUSTOM("Core Options", pink))
    AddToggleOptionST("EnablePlayerVictim_State", "Enable Player as Victim", main.EnablePlayerVictim)
    AddToggleOptionST("EnablePlayerAggressor_State", "Enable Player as Aggressor", main.EnablePlayerAggressor)

    AddHeaderOption(FONT_CUSTOM("Keybinds", blue))
    AddKeyMapOptionST("startAttackKeyCode_State", "Start Assault Key", main.startAttackKeyCode)
    AddKeyMapOptionST("minigame0KeyCode_State", "Minigame Key Left", main.minigame0KeyCode)
    AddKeyMapOptionST("minigame1KeyCode_State", "Minigame Key Right", main.minigame1KeyCode)
    AddKeyMapOptionST("endAttackKeyCode_State", "End Assault Key", main.endAttackKeyCode)

    AddHeaderOption(FONT_CUSTOM("Probabilities", pink))
    AddSliderOptionST("DefeatedAssaultChance_State", "Assault Chance", main.DefeatedAssaultChance)
    AddSliderOptionST("DefeatKillChance_State", "Death Chance", main.DefeatKillChance)
    
    if (release == false)
        AddHeaderOption(FONT_CUSTOM("Dev Options", blue))
        AddToggleOptionST("CheatMode_State", "Enable Cheat Mode", main.cheatMode)
    endif
endEvent

state EnablePlayerVictim_State
    event OnSelectST(string state_id)
        Main.EnablePlayerVictim = !Main.EnablePlayerVictim
        SetToggleOptionValueST(Main.EnablePlayerVictim)
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("If enabled, the player can be assaulted.")
    endevent

    event OnDefaultST(string state_id)
        Main.EnablePlayerVictim = True
        SetToggleOptionValueST(Main.EnablePlayerVictim)
    endevent
endState

state EnablePlayerAggressor_State
    event OnSelectST(string state_id)
        Main.EnablePlayerAggressor = !Main.EnablePlayerAggressor
        SetToggleOptionValueST(Main.EnablePlayerAggressor)
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("If enabled, the player can perform assaults.")
    endevent

    event OnDefaultST(string state_id)
        Main.EnablePlayerAggressor = True
        SetToggleOptionValueST(Main.EnablePlayerAggressor)
    endevent
endState

state startAttackKeyCode_State
	event OnDefaultST(string state_id)
        main.StartAttackKeyCode = 34
        SetKeyMapOptionValueST(34)
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("The key to start a struggle mingame.")
	endevent

	event OnKeyMapChangeST(string state_id, int keycode)
		main.StartAttackKeyCode = keycode
		SetKeyMapOptionValueST(keycode)
	endevent
endstate

state minigame0KeyCode_State
	event OnDefaultST(string state_id)
        main.minigame0KeyCode = 42
        SetKeyMapOptionValueST(42)
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("The left key for the struggle minigame.")
	endevent

	event OnKeyMapChangeST(string state_id, int keycode)
		main.minigame0KeyCode = keycode
		SetKeyMapOptionValueST(keycode)
	endevent
endstate

state minigame1KeyCode_State
	event OnDefaultST(string state_id)
        main.minigame0KeyCode = 54
        SetKeyMapOptionValueST(54)
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("The right key for the struggle minigame.")
	endevent

	event OnKeyMapChangeST(string state_id, int keycode)
		main.minigame1KeyCode = keycode
		SetKeyMapOptionValueST(keycode)
	endevent
endstate

state endAttackKeyCode_State
	event OnDefaultST(string state_id)
        main.endAttackKeyCode = 57
        SetKeyMapOptionValueST(57)
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("The key to end a struggle minigame.")
	endevent

	event OnKeyMapChangeST(string state_id, int keycode)
		main.endAttackKeyCode = keycode
		SetKeyMapOptionValueST(keycode)
	endevent
endstate

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

state DefeatKillChance_State
	event OnDefaultST(string state_id)
		main.DefeatKillChance = 0
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("The chance you will be killed after being assaulted.")
	endevent
	
	event OnSliderOpenST(string state_id)
		SetSliderDialog(main.DefeatKillChance, 0, 100, 1.0, 0)
	endevent
	
	event OnSliderAcceptST(string state_id, float f)
		main.DefeatKillChance = f as int
		SetSliderOptionValueST(f)
	endevent
endstate

state CheatMode_State
    event OnSelectST(string state_id)
        main.cheatMode = !main.cheatMode
        SetToggleOptionValueST(main.cheatMode)
    endevent

    event OnHighlightST(string state_id)
        SetInfoText("YOU ARE A DIRTY CHEATER.")
    endEvent

    event OnDefaultST(string state_id)
        main.cheatMode = False
        SetToggleOptionValueST(main.cheatMode)
    EndEvent
endState

; This just makes life easier sometimes.
Function WriteLog(String OutputLog, bool error = false)
    MiscUtil.PrintConsole("ODefeat: " + OutputLog)
    Debug.Trace("ODefeat: " + OutputLog)
    if (error == true)
        Debug.Notification("ODefeat: " + OutputLog)
    endIF
EndFunction
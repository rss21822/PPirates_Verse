using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Fortnite.com/Game }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }


vote_selection_player_display := class():
    OurPlayer : player
    OurPlayerUI : player_ui
    var Canvas : ?canvas
    var ButtonSubscribed : logic = false
    
    ScoreMessage<localizes>(msg:string):message="{msg}"

    VoteInstructionText : text_block = text_block{
        DefaultTextColor := NamedColors.White
    }
    VoteButton : button_loud = button_loud{}

    StringToMessage<localizes>(value:string) : message = "{value}"

    InitWidget():void=
        SetupCopy()
        Show()

    SetupCopy():void=
        VoteInstructionText.SetText(StringToMessage("Choose the next mode"))
        VoteButton.SetText(StringToMessage("Open Vote"))
        if(ButtonSubscribed = false):
            VoteButton.OnClick().Subscribe(OnVoteButtonClicked)
            set ButtonSubscribed = true

    Show():void=
        if(Canvas?):
            return
        NewCanvas := BuildCanvas()
        OurPlayerUI.AddWidget(NewCanvas, player_ui_slot{ZOrder := 90, InputMode := ui_input_mode.All})
        set Canvas = option{NewCanvas}

    RemoveWidget():void=
        if(RemovedCanvas := Canvas?):
            OurPlayerUI.RemoveWidget(RemovedCanvas)
            set Canvas = false

    BuildCanvas():canvas=
        canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.82}, Maximum := vector2{X := 0.5, Y := 0.82}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot:
                                HorizontalAlignment := horizontal_alignment.Center
                                Padding := margin{Bottom := 6.0}
                                Widget := VoteInstructionText
                            stack_box_slot:
                                HorizontalAlignment := horizontal_alignment.Center
                                Widget := VoteButton

    OnVoteButtonClicked(Message : widget_message):void=
        Print("Vote selection widget pressed.")

vote_selection_widget := class():
    var Displays : [player]vote_selection_player_display = map{}
    var IsActive : logic = false
    var OwningDevice : ?creative_device = false

    SetOwningDevice(InDevice:creative_device):void=
        set OwningDevice = option{InDevice}

    Activate():void=
        if(IsActive = true):
            return
        Print("Vote selection widget activated")
        set IsActive = true
        if(ActiveDevice := OwningDevice?):
            for(Agent : ActiveDevice.GetPlayspace().GetPlayers()):
                AddDisplayForAgent(Agent)
        else:
            Print("Warning: Vote selection widget missing owning device reference.")

    Deactivate():void=
        if(IsActive = false):
            return
        Print("Vote selection widget deactivated")
        set IsActive = false
        ClearDisplays()

    HandlePlayerAdded(InAgent:agent):void=
        if(IsActive = false):
            return
        AddDisplayForAgent(InAgent)

    ClearDisplays():void=
        for(Key->Display : Displays):
            Display.RemoveWidget()
        set Displays = map{}

    AddDisplayForAgent(InAgent:agent):void=
        if(InPlayer := player[InAgent]):
            if(PlayerUI := GetPlayerUI[InPlayer]):
                if(ExistingDisplay := Displays[InPlayer]):
                    ExistingDisplay.Show()
                else:
                    NewDisplay := vote_selection_player_display{
                        OurPlayer := InPlayer,
                        OurPlayerUI := PlayerUI,
                        Canvas := false
                    }
                    NewDisplay.InitWidget()
                    if(set Displays[InPlayer] = NewDisplay){}
            else:
                Print("Warning: Unable to access player UI for vote widget.")

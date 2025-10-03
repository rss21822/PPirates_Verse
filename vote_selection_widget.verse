using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Fortnite.com/Game }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }

vote_selection_widget := class():
    Device : vote_selection_widget_device
    OurPlayerUI : player_ui
    AssociatedPlayer : player
    var Canvas : ?canvas

    ButtonLabel<localizes>(value:string) : message = "{value}"
    BodyText<localizes>(value:string) : message = "{value}"

    VoteTitle:text_block = text_block {
        DefaultTextColor := NamedColors.White,
        DefaultText := BodyText("SELECT GAME MODE")
    }

    VoteDescription:text_block = text_block {
        DefaultTextColor := NamedColors.LightGray,
        DefaultText := BodyText("Cast your vote before the battle starts!")
    }

    VoteButton:button_loud = button_loud {
        DefaultText := ButtonLabel("OPEN VOTE")
    }

    InitWidget():void=
        VoteButton.OnClickEvent().Subscribe(OnVoteButtonClicked)
        NewCanvas := CreateVoteSelectionUI()
        OurPlayerUI.AddWidget(NewCanvas, player_ui_slot{ZOrder := 25, InputMode := ui_input_mode.All})
        set Canvas = option{NewCanvas}

    RemoveWidget():void=
        if(RemovedCanvas := Canvas?):
            OurPlayerUI.RemoveWidget(RemovedCanvas)
        set Canvas = false

    OnVoteButtonClicked(_:button_loud, PlayerInstigator:?player):void=
        if(InstigatorPlayer := PlayerInstigator?):
            Device.HandleVoteButtonClicked(InstigatorPlayer)
        else:
            Device.HandleVoteButtonClicked(AssociatedPlayer)

    CreateVoteSelectionUI():canvas=
        canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.85}, Maximum := vector2{X := 0.5, Y := 0.85}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    Widget := border:
                        BackgroundColor := color{R := 0.08, G := 0.08, B := 0.1, A := 0.85}
                        Padding := margin{Left := 20.0, Right := 20.0, Top := 16.0, Bottom := 16.0}
                        Content := stack_box:
                            Orientation := orientation.Vertical
                            Slots := array:
                                stack_box_slot:
                                    HorizontalAlignment := horizontal_alignment.Center
                                    Padding := margin{Bottom := 6.0}
                                    Widget := VoteTitle
                                stack_box_slot:
                                    HorizontalAlignment := horizontal_alignment.Center
                                    Padding := margin{Bottom := 10.0}
                                    Widget := VoteDescription
                                stack_box_slot:
                                    HorizontalAlignment := horizontal_alignment.Center
                                    Widget := VoteButton

vote_selection_widget_device := class(creative_device):
    var WidgetsPerPlayer : [player]vote_selection_widget = map{}
    var IsActive : logic = false
    VoteButtonClickedInternal : event(player) = event{}

    OnVoteButtonClickedEvent():event(player)=
        VoteButtonClickedInternal

    OnBegin<override>()<suspends>:void=
        Print("Vote selection widget device initialized")
        GetPlayspace().PlayerAddedEvent().Subscribe(HandlePlayerAdded)

    ShowVoteSelectionUI():void=
        if(IsActive = true):
            return
        Print("Showing vote selection UI for all players")
        set IsActive = true

        AllPlayers := GetPlayspace().GetPlayers()
        for (PlayerAgent : AllPlayers):
            AddWidgetForAgent(PlayerAgent)

    HideVoteSelectionUI():void=
        if(IsActive = false):
            return
        Print("Hiding vote selection UI for all players")
        set IsActive = false

        for(Key->Value : WidgetsPerPlayer):
            Value.RemoveWidget()
        set WidgetsPerPlayer = map{}

    HandlePlayerAdded(NewAgent:agent):void=
        if(IsActive = false):
            return
        AddWidgetForAgent(NewAgent)

    AddWidgetForAgent(InAgent:agent):void=
        if(InPlayer := player[InAgent]):
            if(PlayerUI := GetPlayerUI[InPlayer]):
                if(WidgetsPerPlayer[InPlayer] = false):
                    PerPlayerWidget:vote_selection_widget = vote_selection_widget{
                        Device := Self,
                        OurPlayerUI := PlayerUI,
                        AssociatedPlayer := InPlayer
                    }
                    PerPlayerWidget.InitWidget()
                    if(set WidgetsPerPlayer[InPlayer] = PerPlayerWidget){}

    HandleVoteButtonClicked(InPlayer:player):void=
        Print("Player {InPlayer} interacted with vote selection button")
        VoteButtonClickedInternal.Broadcast(InPlayer)

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /Fortnite.com/Game }
using { /Fortnite.com/Teams }
using { /Verse.org/Colors }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Infection Mode用のプレイヤーごとの表示クラス
infection_player_display := class():
    Device : infection_mode_display_device
    OurPlayerUI : player_ui
    var Canvas : ?canvas

    TextShadowOffset:?vector2=option{vector2{X:=2.0,Y:=2.0}}

    StringToMessage<localizes>(value:string) : message = "{value}"

    # チーム人数表示用のテキストブロック
    var RedTeamCount:text_block = text_block {DefaultTextColor := NamedColors.White}
    var BlueTeamCount:text_block = text_block {DefaultTextColor := NamedColors.White}
    var GreenTeamCount:text_block = text_block {DefaultTextColor := NamedColors.White}
    var YellowTeamCount:text_block = text_block {DefaultTextColor := NamedColors.White}

    # チーム名表示
    RedTeamText:text_block = text_block {DefaultTextColor := NamedColors.Red}
    BlueTeamText:text_block = text_block {DefaultTextColor := NamedColors.Blue}
    GreenTeamText:text_block = text_block {DefaultTextColor := NamedColors.Green}
    YellowTeamText:text_block = text_block {DefaultTextColor := NamedColors.Yellow}

    # ステータステキスト（PLAYERS/ELIMINATED）
    var RedStatusText:text_block = text_block {DefaultTextColor := NamedColors.LightGray}
    var BlueStatusText:text_block = text_block {DefaultTextColor := NamedColors.LightGray}
    var GreenStatusText:text_block = text_block {DefaultTextColor := NamedColors.LightGray}
    var YellowStatusText:text_block = text_block {DefaultTextColor := NamedColors.LightGray}

    # モードタイトル
    ModeTitleText:text_block = text_block {DefaultTextColor := NamedColors.Blue}

    InitWidget():void=
        InitDefaultUIValues()
        NewUI := CreateInfectionUI()
        OurPlayerUI.AddWidget(NewUI, player_ui_slot{ZOrder:=10,InputMode := ui_input_mode.None})
        set Canvas = option{NewUI}

    InitDefaultUIValues():void=
        ModeTitleText.SetText(StringToMessage("INFECTION MODE"))

        RedTeamText.SetText(StringToMessage("RED"))
        BlueTeamText.SetText(StringToMessage("BLUE"))
        GreenTeamText.SetText(StringToMessage("GREEN"))
        YellowTeamText.SetText(StringToMessage("YELLOW"))

        RedTeamCount.SetText(StringToMessage("0"))
        BlueTeamCount.SetText(StringToMessage("0"))
        GreenTeamCount.SetText(StringToMessage("0"))
        YellowTeamCount.SetText(StringToMessage("0"))

        RedStatusText.SetText(StringToMessage("PLAYERS"))
        BlueStatusText.SetText(StringToMessage("PLAYERS"))
        GreenStatusText.SetText(StringToMessage("PLAYERS"))
        YellowStatusText.SetText(StringToMessage("PLAYERS"))

    # チーム人数の更新（game_rule_deviceから呼び出される）
    UpdateTeamCounts(RedCount:int, BlueCount:int, GreenCount:int, YellowCount:int):void=
        # 人数表示の更新
        RedTeamCount.SetText(StringToMessage("{RedCount}"))
        BlueTeamCount.SetText(StringToMessage("{BlueCount}"))
        GreenTeamCount.SetText(StringToMessage("{GreenCount}"))
        YellowTeamCount.SetText(StringToMessage("{YellowCount}"))

        # ステータスの更新（0人の場合はELIMINATED）
        if(RedCount = 0):
            RedStatusText.SetText(StringToMessage("ELIMINATED"))
            RedStatusText.SetTextColor(NamedColors.DarkGray)
            RedTeamText.SetTextColor(NamedColors.DarkGray)
        else:
            RedStatusText.SetText(StringToMessage("PLAYERS"))
            RedStatusText.SetTextColor(NamedColors.LightGray)
            RedTeamText.SetTextColor(NamedColors.Red)

        if(BlueCount = 0):
            BlueStatusText.SetText(StringToMessage("ELIMINATED"))
            BlueStatusText.SetTextColor(NamedColors.DarkGray)
            BlueTeamText.SetTextColor(NamedColors.DarkGray)
        else:
            BlueStatusText.SetText(StringToMessage("PLAYERS"))
            BlueStatusText.SetTextColor(NamedColors.LightGray)
            BlueTeamText.SetTextColor(NamedColors.Blue)

        if(GreenCount = 0):
            GreenStatusText.SetText(StringToMessage("ELIMINATED"))
            GreenStatusText.SetTextColor(NamedColors.DarkGray)
            GreenTeamText.SetTextColor(NamedColors.DarkGray)
        else:
            GreenStatusText.SetText(StringToMessage("PLAYERS"))
            GreenStatusText.SetTextColor(NamedColors.LightGray)
            GreenTeamText.SetTextColor(NamedColors.Green)

        if(YellowCount = 0):
            YellowStatusText.SetText(StringToMessage("ELIMINATED"))
            YellowStatusText.SetTextColor(NamedColors.DarkGray)
            YellowTeamText.SetTextColor(NamedColors.DarkGray)
        else:
            YellowStatusText.SetText(StringToMessage("PLAYERS"))
            YellowStatusText.SetTextColor(NamedColors.LightGray)
            YellowTeamText.SetTextColor(NamedColors.Yellow)

    # UIウィジェットを削除
    RemoveWidget():void=
        if(RemovedCanvas := Canvas?):
            OurPlayerUI.RemoveWidget(RemovedCanvas)

    CreateInfectionUI():canvas=
        SetupShadows()

        NewCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{ Minimum:= vector2{X:=0.5, Y:=0.02}, Maximum:= vector2{X:=0.5, Y:=0.02} }
                    Alignment := vector2{X:=0.5, Y:=0.0}
                    SizeToContent := true
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot:
                                HorizontalAlignment := horizontal_alignment.Center
                                Padding := margin{Top:=10.0, Bottom:=15.0}
                                Widget := ModeTitleText

                            stack_box_slot:
                                HorizontalAlignment := horizontal_alignment.Center
                                Widget := stack_box:
                                    Orientation := orientation.Horizontal
                                    Slots := array:
                                        stack_box_slot:
                                            Padding := margin{Left:=20.0, Right:=20.0}
                                            Widget := CreateTeamInfoBox(RedTeamText, RedTeamCount, RedStatusText)
                                        
                                        stack_box_slot:
                                            Padding := margin{Left:=20.0, Right:=20.0}
                                            Widget := CreateTeamInfoBox(BlueTeamText, BlueTeamCount, BlueStatusText)
                                        
                                        stack_box_slot:
                                            Padding := margin{Left:=20.0, Right:=20.0}
                                            Widget := CreateTeamInfoBox(GreenTeamText, GreenTeamCount, GreenStatusText)
                                        
                                        stack_box_slot:
                                            Padding := margin{Left:=20.0, Right:=20.0}
                                            Widget := CreateTeamInfoBox(YellowTeamText, YellowTeamCount, YellowStatusText)
        return NewCanvas

    CreateTeamInfoBox(TeamName:text_block, TeamCount:text_block, StatusText:text_block):stack_box=
        stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Bottom:=4.0}
                    Widget := TeamName
                stack_box_slot:
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Bottom:=2.0}
                    Widget := TeamCount
                stack_box_slot:
                    HorizontalAlignment := horizontal_alignment.Center
                    Widget := StatusText

    SetupShadows():void=
        RedTeamText.SetShadowOffset(TextShadowOffset)
        RedTeamText.SetShadowOpacity(1.0)
        RedTeamText.SetShadowColor(NamedColors.Black)
        
        BlueTeamText.SetShadowOffset(TextShadowOffset)
        BlueTeamText.SetShadowOpacity(1.0)
        BlueTeamText.SetShadowColor(NamedColors.Black)
        
        GreenTeamText.SetShadowOffset(TextShadowOffset)
        GreenTeamText.SetShadowOpacity(1.0)
        GreenTeamText.SetShadowColor(NamedColors.Black)
        
        YellowTeamText.SetShadowOffset(TextShadowOffset)
        YellowTeamText.SetShadowOpacity(1.0)
        YellowTeamText.SetShadowColor(NamedColors.Black)

        ModeTitleText.SetShadowOffset(TextShadowOffset)
        ModeTitleText.SetShadowOpacity(1.0)
        ModeTitleText.SetShadowColor(NamedColors.Black)

# Infection Mode表示デバイス
infection_mode_display_device := class(creative_device):
    var MaybeMyUIPerPlayer:[player]infection_player_display = map{}
    
    var Teams:[]team = array{}
    
    # 現在のチーム人数
    var RedTeamCount:int = 0
    var BlueTeamCount:int = 0
    var GreenTeamCount:int = 0
    var YellowTeamCount:int = 0

    var IsActive : logic = false

    OnBegin<override>()<suspends>:void=
        Print("Infection Mode Display Device initialized")
        
        TeamCollection := GetPlayspace().GetTeamCollection()
        set Teams = TeamCollection.GetTeams()

    # Infection Mode UIを有効化
    ActivateInfectionUI():void=
        Print("Activating Infection Mode UI...")
        set IsActive = true
        
        ClearUI()
        InitializeTeamCounts()
        
        AllPlayers := GetPlayspace().GetPlayers()
        for (L_Agent : AllPlayers):
            AddInfectionCanvas(L_Agent)
        
        GetPlayspace().PlayerAddedEvent().Subscribe(HandleJoiningPlayer)
        
        Print("Infection Mode UI activated!")

    # 初期チーム人数を取得
    InitializeTeamCounts():void=
        TeamCollection := GetPlayspace().GetTeamCollection()
        
        if(Teams.Length > 0):
            if(Team1Players := TeamCollection.GetAgents[Teams[0]]):
                set RedTeamCount = Team1Players.Length
        
        if(Teams.Length > 1):
            if(Team2Players := TeamCollection.GetAgents[Teams[1]]):
                set BlueTeamCount = Team2Players.Length
        
        if(Teams.Length > 2):
            if(Team3Players := TeamCollection.GetAgents[Teams[2]]):
                set GreenTeamCount = Team3Players.Length
        
        if(Teams.Length > 3):
            if(Team4Players := TeamCollection.GetAgents[Teams[3]]):
                set YellowTeamCount = Team4Players.Length
        
        Print("Initial team counts - Red:{RedTeamCount} Blue:{BlueTeamCount} Green:{GreenTeamCount} Yellow:{YellowTeamCount}")

    # UIをクリア
    ClearUI():void=
        for(Key->Value : MaybeMyUIPerPlayer):
            Value.RemoveWidget()
        set MaybeMyUIPerPlayer = map{}

    # プレイヤー参加時の処理
    HandleJoiningPlayer(InAgent:agent):void=
        if(IsActive = true):
            AddInfectionCanvas(InAgent)

    # Infection用キャンバス追加
    AddInfectionCanvas(InAgent:agent):void=
        if (InPlayer := player[InAgent], PlayerUI := GetPlayerUI[InPlayer]):
            if (not MaybeMyUIPerPlayer[InPlayer]):
                PerPlayerDisplay:infection_player_display=infection_player_display{
                    Device:=Self,
                    OurPlayerUI:=PlayerUI,
                    Canvas:=false
                }
                PerPlayerDisplay.InitWidget()
                PerPlayerDisplay.UpdateTeamCounts(RedTeamCount, BlueTeamCount, GreenTeamCount, YellowTeamCount)
                if (set MaybeMyUIPerPlayer[InPlayer] = PerPlayerDisplay) {}

    # game_rule_deviceから呼び出される更新メソッド
    UpdateTeamCounts(Team1Count:int, Team2Count:int, Team3Count:int, Team4Count:int):void=
        set RedTeamCount = Team1Count
        set BlueTeamCount = Team2Count
        set GreenTeamCount = Team3Count
        set YellowTeamCount = Team4Count
        
        # 全プレイヤーのUIを更新
        for (Key->Value : MaybeMyUIPerPlayer):
            Value.UpdateTeamCounts(RedTeamCount, BlueTeamCount, GreenTeamCount, YellowTeamCount)
        
        Print("UI Updated - Red:{RedTeamCount} Blue:{BlueTeamCount} Green:{GreenTeamCount} Yellow:{YellowTeamCount}")

    # UIの非表示
    DeactivateUI():void=
        set IsActive = false
        ClearUI()
        Print("Infection Mode UI deactivated")
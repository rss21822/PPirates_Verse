using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /Fortnite.com/Game }
using { /Verse.org/Colors }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

# プレイヤーごとの表示クラス
perplayerdisplay:=class(){  
    Device : team_score_display_device
    OurPlayerUI : player_ui
    var Canvas : ?canvas

    TextShadowOffset:?vector2=option{vector2{X:=2.0,Y:=2.0}}

    StringToMessage<localizes>(value:string) : message = "{value}"

    var TeamOneScore:text_block = text_block {DefaultTextColor := NamedColors.White}
    var TeamTwoScore:text_block = text_block {DefaultTextColor := NamedColors.White}
    var TeamThreeScore:text_block = text_block {DefaultTextColor := NamedColors.White}
    var TeamFourScore:text_block = text_block {DefaultTextColor := NamedColors.White}

    # モードタイトル
    ModeTitleText:text_block = text_block {DefaultTextColor := NamedColors.Red}
    
    # KILLS表記
    RedKillsText:text_block = text_block {DefaultTextColor := NamedColors.LightGray}
    BlueKillsText:text_block = text_block {DefaultTextColor := NamedColors.LightGray}
    GreenKillsText:text_block = text_block {DefaultTextColor := NamedColors.LightGray}
    YellowKillsText:text_block = text_block {DefaultTextColor := NamedColors.LightGray}
    
    RedTeamText:text_block = text_block {DefaultTextColor := NamedColors.Red}
    BlueTeamText:text_block = text_block {DefaultTextColor := NamedColors.Blue}
    GreenTeamText:text_block = text_block {DefaultTextColor := NamedColors.Green}
    YellowTeamText:text_block = text_block {DefaultTextColor := NamedColors.Yellow}

    InitWidget():void=
        InitDefaultUIValues()
        NewUI := CreateMyUI()
        OurPlayerUI.AddWidget(NewUI, player_ui_slot{ZOrder:=10,InputMode := ui_input_mode.None})
        set Canvas = option{NewUI}

    InitDefaultUIValues():void=
        # モードタイトル
        ModeTitleText.SetText(StringToMessage("DEATHMATCH MODE"))
        
        # チーム名
        RedTeamText.SetText(StringToMessage("RED"))
        BlueTeamText.SetText(StringToMessage("BLUE"))
        GreenTeamText.SetText(StringToMessage("GREEN"))
        YellowTeamText.SetText(StringToMessage("YELLOW"))

        # KILLS表記
        RedKillsText.SetText(StringToMessage("KILLS"))
        BlueKillsText.SetText(StringToMessage("KILLS"))
        GreenKillsText.SetText(StringToMessage("KILLS"))
        YellowKillsText.SetText(StringToMessage("KILLS"))

        # 初期スコア
        TeamOneScore.SetText(StringToMessage("0"))
        TeamTwoScore.SetText(StringToMessage("0"))
        TeamThreeScore.SetText(StringToMessage("0"))
        TeamFourScore.SetText(StringToMessage("0"))

    UpdateUI(InTeamOneScore:int,InTeamTwoScore:int,InTeamThreeScore:int,InTeamFourScore:int):void=
        Print("TeamOneScore:" + "{InTeamOneScore}")
        Print("TeamTwoScore:" + "{InTeamTwoScore}")
        TeamOneScore.SetText(StringToMessage(ToString(InTeamOneScore)))
        TeamTwoScore.SetText(StringToMessage(ToString(InTeamTwoScore)))
        TeamThreeScore.SetText(StringToMessage(ToString(InTeamThreeScore)))
        TeamFourScore.SetText(StringToMessage(ToString(InTeamFourScore)))

    # UIウィジェットを削除
    RemoveWidget():void=
        if(RemovedCanvas := Canvas?):
            OurPlayerUI.RemoveWidget(RemovedCanvas)

    CreateMyUI():canvas=
        # シャドウ設定
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
                            # モードタイトル
                            stack_box_slot:
                                HorizontalAlignment := horizontal_alignment.Center
                                Padding := margin{Top:=10.0, Bottom:=15.0}
                                Widget := ModeTitleText

                            # チーム情報コンテナ
                            stack_box_slot:
                                HorizontalAlignment := horizontal_alignment.Center
                                Widget := stack_box:
                                    Orientation := orientation.Horizontal
                                    Slots := array:
                                        # RED Team
                                        stack_box_slot:
                                            Padding := margin{Left:=20.0, Right:=20.0}
                                            Widget := CreateTeamScoreBox(RedTeamText, TeamOneScore, RedKillsText)
                                        
                                        # BLUE Team
                                        stack_box_slot:
                                            Padding := margin{Left:=20.0, Right:=20.0}
                                            Widget := CreateTeamScoreBox(BlueTeamText, TeamTwoScore, BlueKillsText)
                                        
                                        # GREEN Team
                                        stack_box_slot:
                                            Padding := margin{Left:=20.0, Right:=20.0}
                                            Widget := CreateTeamScoreBox(GreenTeamText, TeamThreeScore, GreenKillsText)
                                        
                                        # YELLOW Team
                                        stack_box_slot:
                                            Padding := margin{Left:=20.0, Right:=20.0}
                                            Widget := CreateTeamScoreBox(YellowTeamText, TeamFourScore, YellowKillsText)
        return NewCanvas

    # チームスコアボックスの作成
    CreateTeamScoreBox(TeamName:text_block, TeamScore:text_block, KillsText:text_block):stack_box=
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
                    Widget := TeamScore
                stack_box_slot:
                    HorizontalAlignment := horizontal_alignment.Center
                    Widget := KillsText

    # シャドウの設定
    SetupShadows():void=
        # スコアのシャドウ
        TeamOneScore.SetShadowOffset(TextShadowOffset)
        TeamOneScore.SetShadowOpacity(1.0)
        TeamOneScore.SetShadowColor(NamedColors.Black)
        TeamTwoScore.SetShadowOffset(TextShadowOffset)
        TeamTwoScore.SetShadowOpacity(1.0)
        TeamTwoScore.SetShadowColor(NamedColors.Black)
        TeamThreeScore.SetShadowOffset(TextShadowOffset)
        TeamThreeScore.SetShadowOpacity(1.0)
        TeamThreeScore.SetShadowColor(NamedColors.Black)
        TeamFourScore.SetShadowOffset(TextShadowOffset)
        TeamFourScore.SetShadowOpacity(1.0)
        TeamFourScore.SetShadowColor(NamedColors.Black)

        # チーム名のシャドウ
        BlueTeamText.SetShadowOffset(TextShadowOffset)
        BlueTeamText.SetShadowOpacity(1.0)
        BlueTeamText.SetShadowColor(NamedColors.Black)
        RedTeamText.SetShadowOffset(TextShadowOffset)
        RedTeamText.SetShadowOpacity(1.0)
        RedTeamText.SetShadowColor(NamedColors.Black)
        GreenTeamText.SetShadowOffset(TextShadowOffset)
        GreenTeamText.SetShadowOpacity(1.0)
        GreenTeamText.SetShadowColor(NamedColors.Black)
        YellowTeamText.SetShadowOffset(TextShadowOffset)
        YellowTeamText.SetShadowOpacity(1.0)
        YellowTeamText.SetShadowColor(NamedColors.Black)
        
        # モードタイトルのシャドウ
        ModeTitleText.SetShadowOffset(TextShadowOffset)
        ModeTitleText.SetShadowOpacity(1.0)
        ModeTitleText.SetShadowColor(NamedColors.Black)
        
        # KILLS表記のシャドウ
        RedKillsText.SetShadowOffset(TextShadowOffset)
        RedKillsText.SetShadowOpacity(1.0)
        BlueKillsText.SetShadowOffset(TextShadowOffset)
        BlueKillsText.SetShadowOpacity(1.0)
        GreenKillsText.SetShadowOffset(TextShadowOffset)
        GreenKillsText.SetShadowOpacity(1.0)
        YellowKillsText.SetShadowOffset(TextShadowOffset)
        YellowKillsText.SetShadowOpacity(1.0)
}

# メインのチームスコア表示デバイス
team_score_display_device := class(creative_device):
    var MaybeMyUIPerPlayer:[player]perplayerdisplay = map{}
    var TeamOneKills:int=0
    var TeamTwoKills:int=0
    var TeamThreeKills:int=0
    var TeamFourKills:int=0
      var DeathmatchHandlersBound : logic = false
      var DeathmatchPlayerAddedSubscribed : logic = false
    
    # ゲームモードフラグ
    var IsDeathmatchMode : logic = false
    var IsInfectionMode : logic = false

    @editable 
    TeamOneRed : team_settings_and_inventory_device = team_settings_and_inventory_device{}
    @editable 
    TeamTwoBlue : team_settings_and_inventory_device = team_settings_and_inventory_device{}
    @editable 
    TeamThreeGreen : team_settings_and_inventory_device = team_settings_and_inventory_device{}
    @editable   
    TeamFourYellow : team_settings_and_inventory_device = team_settings_and_inventory_device{}

    # OnBeginでは初期化のみ行い、UIは作成しない
    OnBegin<override>()<suspends>:void=
        Print("Team Score Display Device initialized - waiting for game mode selection...")

    # Deathmatch Mode（撃破数表示）を有効化
    ActivateDeathmatchMode():void=
        Print("Activating Deathmatch Mode UI...")
        set IsDeathmatchMode = true
        set IsInfectionMode = false

        ResetKillCounts()
        ClearUI()

        if(DeathmatchHandlersBound = false):
            TeamOneRed.EnemyEliminatedEvent.Subscribe(OnTeamOneScore)
            TeamTwoBlue.EnemyEliminatedEvent.Subscribe(OnTeamTwoScore)
            TeamThreeGreen.EnemyEliminatedEvent.Subscribe(OnTeamThreeScore)
            TeamFourYellow.EnemyEliminatedEvent.Subscribe(OnTeamFourScore)
            set DeathmatchHandlersBound = true

        AllPlayers := GetPlayspace().GetPlayers()
        for (L_Agent : AllPlayers):
            HandleJoiningPlayer(L_Agent)

        if(DeathmatchPlayerAddedSubscribed = false):
            GetPlayspace().PlayerAddedEvent().Subscribe(HandleJoiningPlayer)
            set DeathmatchPlayerAddedSubscribed = true

        UpdateUI(TeamOneKills,TeamTwoKills,TeamThreeKills,TeamFourKills)

        Print("Deathmatch Mode UI activated!")
    DeactivateDeathmatchMode():void=
        if(IsDeathmatchMode = false):
            return

        Print("Deactivating Deathmatch Mode UI...")
        set IsDeathmatchMode = false
        ClearUI()
        ResetKillCounts()
    # Infection Mode（残り人数表示）を有効化
    ActivateInfectionMode():void=
        Print("Activating Infection Mode UI...")
        DeactivateDeathmatchMode()
        set IsInfectionMode = true
        set IsDeathmatchMode = false

        ClearUI()

        Print("Infection Mode UI activated!")
    # UIをクリア
    ClearUI():void=
        for(Key->Value : MaybeMyUIPerPlayer):
            Value.RemoveWidget()
        set MaybeMyUIPerPlayer = map{}

    ResetKillCounts()<transacts>:void=
        set TeamOneKills = 0
        set TeamTwoKills = 0
        set TeamThreeKills = 0
        set TeamFourKills = 0

    # Classic Mode用のプレイヤー追加処理
    HandleJoiningPlayer(InAgent:agent):void=
        if(IsDeathmatchMode = true):
            AddCanvas(InAgent)

    # Infection Mode用のプレイヤー追加処理（後で実装）
    HandleJoiningPlayerInfection(InAgent:agent):void=
        if(IsInfectionMode = true):
            # Infection Mode用のUIを追加（別途実装）
            AddCanvasInfection(InAgent)

    # Classic Mode用のキャンバス追加
    AddCanvas(InAgent:agent):void=
        if (InPlayer := player[InAgent], PlayerUI := GetPlayerUI[InPlayer]):
            if (not MaybeMyUIPerPlayer[InPlayer]):
                PerPlayerDisplay:perplayerdisplay=perplayerdisplay{
                    Device:=Self,
                    OurPlayerUI:=PlayerUI,
                    Canvas:=false
                }
                PerPlayerDisplay.InitWidget()
                PerPlayerDisplay.UpdateUI(TeamOneKills, TeamTwoKills, TeamThreeKills, TeamFourKills)
                if (set MaybeMyUIPerPlayer[InPlayer] = PerPlayerDisplay) {}

    # Infection Mode用のキャンバス追加（簡易実装）
    AddCanvasInfection(InAgent:agent):void=
        # ここにInfection Mode用のUI実装を追加
        # 現在は基本的な実装のみ
        if (InPlayer := player[InAgent], PlayerUI := GetPlayerUI[InPlayer]):
            Print("Adding Infection Mode UI for player...")

    # UI更新（Classic Mode用）
    UpdateUI(InTeamOneScore:int,InTeamTwoScore:int,InTeamThreeScore:int,InTeamFourScore:int):void=
        if(IsDeathmatchMode = true):
            for (Key->Value : MaybeMyUIPerPlayer):
                Value.UpdateUI(InTeamOneScore,InTeamTwoScore,InTeamThreeScore,InTeamFourScore)

    # UI更新（Infection Mode用）
    UpdateUIInfection(Team1Count:int, Team2Count:int, Team3Count:int, Team4Count:int):void=
        if(IsInfectionMode = true):
            # Infection Mode用のUI更新処理（後で実装）
            Print("Updating Infection UI - Red:{Team1Count} Blue:{Team2Count} Green:{Team3Count} Yellow:{Team4Count}")

    # チームスコア処理
    OnTeamOneScore(InAgent:agent):void=
        if(IsDeathmatchMode = true):
            IncTeamOneKills()
            UpdateUI(TeamOneKills,TeamTwoKills,TeamThreeKills,TeamFourKills)

    OnTeamTwoScore(InAgent:agent):void=
        if(IsDeathmatchMode = true):
            IncTeamTwoKills()
            UpdateUI(TeamOneKills,TeamTwoKills,TeamThreeKills,TeamFourKills)

    OnTeamThreeScore(InAgent:agent):void=
        if(IsDeathmatchMode = true):
            IncTeamThreeKills()
            UpdateUI(TeamOneKills,TeamTwoKills,TeamThreeKills,TeamFourKills)

    OnTeamFourScore(InAgent:agent):void=
        if(IsDeathmatchMode = true):
            IncTeamFourKills()
            UpdateUI(TeamOneKills,TeamTwoKills,TeamThreeKills,TeamFourKills)

    # キル数増加処理
    IncTeamOneKills()<transacts>:void=
        Print("Red Team Score +1")
        set TeamOneKills += 1

    IncTeamTwoKills()<transacts>:void=
        Print("Blue Team Score +1")
        set TeamTwoKills += 1

    IncTeamThreeKills()<transacts>:void=
        Print("Green Team Score +1")
        set TeamThreeKills += 1

    IncTeamFourKills()<transacts>:void=
        Print("Yellow Team Score +1")
        set TeamFourKills += 1

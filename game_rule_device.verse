using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Teams}
using { /Fortnite.com/FortPlayerUtilities }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters}
using { /Fortnite.com/Game}
using { /Fortnite.com/UI }
using { /Verse.org/Colors }
using { /Verse.org/Random }

# Pilfering Pirates - Infection Mode Device
game_rule_device := class(creative_device): 
    # team_score_display_deviceへの参照を追加
    @editable
    TeamScoreDisplay : team_score_display_device = team_score_display_device{}
    @editable
    InfectionDisplay : infection_mode_display_device = infection_mode_display_device{} 

    #// SHIP
    @editable
    Ship2 : creative_prop = creative_prop{}
    @editable
    Ship3 : creative_prop = creative_prop{}
    @editable
    Ship4 : creative_prop = creative_prop{}
    
    #// 投票時間終了タイマー
    @editable
    vote_group : vote_group_device = vote_group_device{}

    #// チームごとのプレイヤースポナーを@editableで割り当て
    @editable
    player_teleportor_team1 : []teleporter_device  = array{}
    @editable
    player_teleportor_team2 : []teleporter_device  = array{}
    @editable
    player_teleportor_team3 : []teleporter_device  = array{}
    @editable
    player_teleportor_team4 : []teleporter_device  = array{}

    #// チームごとのクラスセレクターを@editableで割り当て
    @editable
    class_selector1 : class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    class_selector2 : class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    class_selector3 : class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    class_selector4 : class_and_team_selector_device = class_and_team_selector_device{}
 
    var Teams:[]team = array{}
    
    #// プレイヤーとチーム情報のリスト
    var players_and_teams : [player]team = map{}
    #// プレイヤー数とチームのリスト
    var teams_playerCount_length : [team]int = map{}
    # 撃破されたチーム
    var eliminatedTeams : []team = array{}
    
    # Infectionモード有効フラグ
    var IsInfectionMode : logic = false
    var PlayerAddedSubscribed : logic = false
    
    # チーム変更エフェクト用（オプション）
    @editable
    TeamChangeVFX : visual_effect_powerup_device = visual_effect_powerup_device{}
    
    #// 投票オプション
    @editable
    vote_optionA : vote_option_device = vote_option_device {}
    @editable
    vote_optionB : vote_option_device = vote_option_device {}
    
    #@editable
    #vote_optionC : vote_option_device = vote_option_device {}
    #@editable
    #vote_optionD : vote_option_device = vote_option_device {}
    
    @editable 
    TeamOneRed : team_settings_and_inventory_device = team_settings_and_inventory_device{}
    @editable 
    TeamTwoBlue : team_settings_and_inventory_device = team_settings_and_inventory_device{}

    @editable
    EndGame : end_game_device = end_game_device{}

    @editable
    HUDMessage : hud_message_device = hud_message_device{}
    
    # デバッグ用 & チームバランス表示用
    @editable
    TeamBalanceText : billboard_device = billboard_device{}
    @editable
    GameModeText : billboard_device = billboard_device{}

    ScoreMessage<localizes>(msg:string):message="{msg}"
    TeamBalanceMessage<localizes>(team1:int, team2:int, team3:int, team4:int):message="Red:{team1} Blue:{team2} Green:{team3} Yellow:{team4}"
    
    #// OnBeginで全プレイヤーとチーム情報を収集、タイマー成功イベントをSubscribe
    OnBegin<override>()<suspends> : void =

        # Teams 配列を島設定のチーム構成で更新
        TeamCollection := GetPlayspace().GetTeamCollection()
        set Teams = TeamCollection.GetTeams()

        # 初期チーム人数を設定
        for(Team : Teams):
            if(TeamPlayers := TeamCollection.GetAgents[Team].Length):
                if(set teams_playerCount_length[Team] = TeamPlayers):
                    Print("Team initialized with {TeamPlayers} players")

        # 投票イベントの登録
        vote_optionA.WinVoteEvent.Subscribe(OnVoteASuccess)
        vote_optionB.WinVoteEvent.Subscribe(OnVoteBSuccess)
        #vote_optionC.WinVoteEvent.Subscribe(OnVoteCSuccess)
        #vote_optionD.WinVoteEvent.Subscribe(OnVoteDSuccess)
    
        vote_group.EndVoteEvent.Subscribe(player_teleport)
        vote_group.VoteTiedEvent.Subscribe(randam_vote_select)

    # 投票終了後に全プレイヤーをチーム別にテレポート
    player_teleport() : void =
        Print("Vote ended - Teleporting players to their team ships...")

        TeamCollection := GetPlayspace().GetTeamCollection()
        AllPlayers := GetPlayspace().GetPlayers()

        for (Player : AllPlayers):
            # プレイヤーのチームを取得
            if (PlayerTeam := TeamCollection.GetTeam[Player]):
                # チームに応じてテレポート
                if (PlayerTeam = Teams[0]):
                    # Team 1 (Red) - ランダムなテレポーターを選択
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team1, "Red")
                else if (PlayerTeam = Teams[1]):
                    # Team 2 (Blue)
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team2, "Blue")
                else if (PlayerTeam = Teams[2]):
                    # Team 3 (Green)
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team3, "Green")
                else if (PlayerTeam = Teams[3]):
                    # Team 4 (Yellow)
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team4, "Yellow")

        Print("All players teleported to their team ships!")


    # 引き分け時にVote A、Bどちらかをランダムで選択し、player_teleport()を呼び出す
    randam_vote_select() : void =
        Print("Vote tied! Randomly selecting game mode...")

        # 0または1をランダムに生成 (Vote A or Vote B)
        RandomChoice := GetRandomInt(0, 1)

        if (RandomChoice = 0):
            # Vote A (Deathmatch) を選択
            Print("Random selection: Deathmatch Mode")
            OnVoteASuccess(false)
        else:
            # Vote B (Infection) を選択
            Print("Random selection: Infection Mode")
            OnVoteBSuccess(false)

        # 全プレイヤーをテレポート
        player_teleport()

    # プレイヤーをランダムなテレポーターデバイスにテレポート
    TeleportPlayerToRandomDevice(Player : agent, Teleporters : []teleporter_device, TeamName : string) : void =
        if (Teleporters.Length > 0):
            # ランダムなインデックスを生成
            RandomIndex := GetRandomInt(0, Teleporters.Length - 1)

            if (SelectedTeleporter := Teleporters[RandomIndex]):
                SelectedTeleporter.Teleport(Player)
                Print("Player teleported to {TeamName} team ship (teleporter #{RandomIndex})")
            else:
                Print("Warning: Failed to get teleporter at index {RandomIndex} for {TeamName} team")
        else:
            Print("Warning: No teleporters configured for {TeamName} team")
        
    # -----------------------------------Vote A-----------------------------------
    OnVoteASuccess(InPlayer : ?agent) : void =
        Print("Deathmatch Mode Selected")  # ← 修正
        GameModeText.SetText(ScoreMessage("Mode: Deathmatch"))  # ← 修正
        set IsInfectionMode = false
        
        InfectionDisplay.DeactivateUI()
        
        # Deathmatch　Mode UIを有効化
        TeamScoreDisplay.ActivateDeathmatchMode()

    # -----------------------------------Vote B - Infection Mode-----------------------------------
    OnVoteBSuccess(InPlayer : ?agent) : void =
        Print("Infection Mode Started")
        GameModeText.SetText(ScoreMessage("Mode: Infection"))
        set IsInfectionMode = true
        
        set eliminatedTeams = array{}
        TeamScoreDisplay.ActivateInfectionMode()

        if(PlayerAddedSubscribed = false):
            GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
            set PlayerAddedSubscribed = true
        
        # Infection Mode UIを有効化
        InfectionDisplay.ActivateInfectionUI()
        
        # 初期のチーム人数でUIを更新（少し遅延を入れて確実に）
        spawn{InitialInfectionUIUpdate()}
        
        # 全プレイヤーのEliminatedEventを購読
        AllPlayers := GetPlayspace().GetPlayers()
        for (Player : AllPlayers):
            if (FortCharacter := Player.GetFortCharacter[]):
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminatedInfection)
        
        HUDMessage.SetText(ScoreMessage("Infection Mode: Eliminate enemies to recruit them!"))
        HUDMessage.Show()
        

    OnPlayerAdded(InPlayer : player) : void =
        if(IsInfectionMode = false):
            return

        Print("New player joined the game!")
        
        # Infectionモードの撃破イベントを購読
        if(IsInfectionMode = true):
            if(FortCharacter := InPlayer.GetFortCharacter[]):
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminatedInfection)
        
        # プレイヤーを自チームの船にテレポート（少し遅延）
        spawn{TeleportLateJoiningPlayer(InPlayer)}

    TeleportLateJoiningPlayer(InPlayer : player)<suspends> : void =
        if(IsInfectionMode = false):
            return

        Sleep(1.0)  # キャラクター生成完了を待つ
        
        TeamCollection := GetPlayspace().GetTeamCollection()
        if(PlayerTeam := TeamCollection.GetTeam[InPlayer]):
            if (PlayerTeam = Teams[0]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team1, "Red")
            else if (PlayerTeam = Teams[1]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team2, "Blue")
            else if (PlayerTeam = Teams[2]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team3, "Green")
            else if (PlayerTeam = Teams[3]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team4, "Yellow")
    
    # -----------------------------------Vote C-----------------------------------
    <#
    OnVoteCSuccess(InPlayer : ?agent) : void =
        Print("Mega Ships Mode Selected")
        GameModeText.SetText(ScoreMessage("Mode: Mega Ships"))
        set IsInfectionMode = false
    #>
    # -----------------------------------Vote D-----------------------------------
    <#
    OnVoteDSuccess(InPlayer : ?agent) : void =
        Print("Deathmatch Mode Selected")
        GameModeText.SetText(ScoreMessage("Mode: Deathmatch"))
        set IsInfectionMode = false
    #>

    # 初期UI更新（遅延を入れて確実に初期値を取得）
    InitialInfectionUIUpdate()<suspends> : void =
        Sleep(0.5)
        UpdateInfectionUI()

    # Infectionモード専用の撃破処理
    OnPlayerEliminatedInfection(Result : elimination_result) : void =
        if(IsInfectionMode = false):
            return

        Print("Player eliminated in Infection mode!")
    
        EliminatorPlayer := Result.EliminatingCharacter
        EliminatedPlayer := Result.EliminatedCharacter
    
        if (EliminatedFortCharacter := EliminatedPlayer, EliminatedAgent := EliminatedFortCharacter.GetAgent[]):
            if(EliminatedPlayerTeam := GetPlayspace().GetTeamCollection().GetTeam[EliminatedAgent]):
                if (EliminationFortCharacter := EliminatorPlayer?, EliminatorAgent := EliminationFortCharacter.GetAgent[]):
                    if(EliminatorPlayerTeam := GetPlayspace().GetTeamCollection().GetTeam[EliminatorAgent]):
                        
                        # 異なるチーム間の撃破のみ処理
                        if(EliminatedPlayerTeam <> EliminatorPlayerTeam):
                            Print("Team change: Player moving to new team")

                            # チーム変更の実行
                            PerformTeamChange(EliminatedAgent, EliminatorPlayerTeam)

                            # チーム変更通知
                            if(AfterEliminatedPlayer := player[EliminatedAgent]):
                                ShowTeamChangeNotification(AfterEliminatedPlayer, EliminatorPlayerTeam)

                            # Infectionモード: 新しいチームの船にテレポート
                            spawn{TeleportToNewTeamShip(EliminatedAgent, EliminatorPlayerTeam)}

                            # UI更新を遅延実行（チーム変更が完了してから）
                            spawn{DelayedInfectionUIUpdate()}
                        else:
                            # 同一チーム内での撃破（フレンドリーファイア）
                            Print("Friendly fire detected - no team change")
    
        # 終了条件のチェック
        CheckInfectionEndCondition(EliminatorPlayer)
        
        # チーム全滅の確認と通知
        CheckEliminatedTeams()

    # 遅延UI更新（チーム変更が完了してから）
    DelayedInfectionUIUpdate()<suspends> : void =
        Sleep(0.3)
        UpdateInfectionUI()

    # Infectionモード: チーム変更後に新しいチームの船にテレポート
    TeleportToNewTeamShip(Agent : agent, NewTeam : team)<suspends> : void =
        if(IsInfectionMode = false):
            return

        # チーム変更が完了するまで少し待機
        Sleep(0.5)

        var TeamName : string = "Unknown"
        var TargetTeleporters : []teleporter_device = array{}

        # 新しいチームに応じてテレポーター配列を選択
        if (NewTeam = Teams[0]):
            set TargetTeleporters = player_teleportor_team1
            set TeamName = "Red"
        else if (NewTeam = Teams[1]):
            set TargetTeleporters = player_teleportor_team2
            set TeamName = "Blue"
        else if (NewTeam = Teams[2]):
            set TargetTeleporters = player_teleportor_team3
            set TeamName = "Green"
        else if (NewTeam = Teams[3]):
            set TargetTeleporters = player_teleportor_team4
            set TeamName = "Yellow"

        # ランダムなテレポーターにテレポート
        TeleportPlayerToRandomDevice(Agent, TargetTeleporters, TeamName)
        Print("Infection: Player teleported to {TeamName} team ship after team change")

    # Infection UI専用の更新メソッド
    UpdateInfectionUI() : void =
        TeamCollection := GetPlayspace().GetTeamCollection()
        var Team1Count : int = 0    
        var Team2Count : int = 0
        var Team3Count : int = 0
        var Team4Count : int = 0
        
        if(Teams.Length > 0):
            if(Team1Agents := TeamCollection.GetAgents[Teams[0]]):
                set Team1Count = Team1Agents.Length
        
        if(Teams.Length > 1):
            if(Team2Agents := TeamCollection.GetAgents[Teams[1]]):
                set Team2Count = Team2Agents.Length
        
        if(Teams.Length > 2):
            if(Team3Agents := TeamCollection.GetAgents[Teams[2]]):
                set Team3Count = Team3Agents.Length
        
        if(Teams.Length > 3):
            if(Team4Agents := TeamCollection.GetAgents[Teams[3]]):
                set Team4Count = Team4Agents.Length
        
        # InfectionDisplay更新（ここが重要！）
        InfectionDisplay.UpdateTeamCounts(Team1Count, Team2Count, Team3Count, Team4Count)
        
        # デバッグ用Billboard更新
        TeamBalanceText.SetText(TeamBalanceMessage(Team1Count, Team2Count, Team3Count, Team4Count))

    # チーム変更の実行
    PerformTeamChange(Agent : agent, NewTeam : team) : void =
        if (NewTeam = Teams[0]):
            class_selector1.ChangeTeam(Agent)
            Print("Player joined Red Team")
        else if (NewTeam = Teams[1]):
            class_selector2.ChangeTeam(Agent)
            Print("Player joined Blue Team")
        else if (NewTeam = Teams[2]):
            class_selector3.ChangeTeam(Agent)
            Print("Player joined Green Team")
        else if (NewTeam = Teams[3]):
            class_selector4.ChangeTeam(Agent)
            Print("Player joined Yellow Team")

    # チーム変更の通知
    ShowTeamChangeNotification(Player : player, NewTeam : team) : void =
        var TeamName : string = "Unknown"
        
        if (NewTeam = Teams[0]):
            set TeamName = "Red"
        else if (NewTeam = Teams[1]):
            set TeamName = "Blue"
        else if (NewTeam = Teams[2]):
            set TeamName = "Green"
        else if (NewTeam = Teams[3]):
            set TeamName = "Yellow"
            
        NotificationMessage := ScoreMessage("You have been recruited to {TeamName} Team!")
        HUDMessage.SetText(NotificationMessage)
        HUDMessage.Show(Player)
        
        # ビジュアルエフェクト（設定されている場合）
        if(FortCharacter := Player.GetFortCharacter[]):
            TeamChangeVFX.Pickup(Player)

    # Infection終了条件のチェック
    CheckInfectionEndCondition(EliminatorPlayer : ?fort_character) : void =
        Print("Checking Infection end condition")
        
        TeamCollection := GetPlayspace().GetTeamCollection()
        var ActiveTeams : int = 0
        var WinningTeam : ?team = false
        
        # アクティブなチームをカウント
        for (i := 0..3):
            if (i < Teams.Length):
                if (TeamCollection.GetAgents[Teams[i]].Length > 0):
                    set ActiveTeams += 1
                    set WinningTeam = option{Teams[i]}
        
        Print("Active teams: {ActiveTeams}")
        
        # 1チームだけ残った場合（全員が一つのチームに集まった）
        if (ActiveTeams = 1):
            var VictoryAgent : ?agent = false

            # 通常の対人キルで勝利した場合は淘汰側のエージェントを使う
            if (EliminatedFortCharacter := fort_character[EliminatorPlayer?], EliminatedAgent := EliminatedFortCharacter.GetAgent[]):
                set VictoryAgent = option{EliminatedAgent}
            # 環境ダメージなどで Eliminator が不明な場合は勝利チームの誰かを探す
            else if (WinningTeamValue := WinningTeam?):
                if(WinningTeamAgents := TeamCollection.GetAgents[WinningTeamValue]):
                    if (WinningTeamAgents.Length > 0):
                        if (FirstAgent := WinningTeamAgents[0]):
                            set VictoryAgent = option{FirstAgent}

            if (UnwrappedVictoryAgent := VictoryAgent?):
                Print("Infection Victory! All players united in one team!")
                EndGame.Activate(UnwrappedVictoryAgent)
            else:
                Print("Infection victory detected, but no agent available to trigger EndGame.")

    # チーム全滅の確認と通知
    CheckEliminatedTeams() : void =
        TeamCollection := GetPlayspace().GetTeamCollection()
        
        # チーム1（Red）人数確認
        if(Teams.Length > 0):
            if(TeamCollection.GetAgents[Teams[0]].Length = 0):
                if(not eliminatedTeams.Find[Teams[0]]):
                    if(set eliminatedTeams += array{Teams[0]}):
                        Print("Red Team is Eliminated!")
                        HUDMessage.SetText(ScoreMessage("Red Team is Eliminated!"))
                        HUDMessage.Show()

        # チーム2（Blue）人数確認
        if(Teams.Length > 1):
            if(TeamCollection.GetAgents[Teams[1]].Length = 0):
                if(not eliminatedTeams.Find[Teams[1]]):
                    if(set eliminatedTeams += array{Teams[1]}):
                        Print("Blue Team is Eliminated!")
                        HUDMessage.SetText(ScoreMessage("Blue Team is Eliminated!"))
                        HUDMessage.Show()

        # チーム3（Green）人数確認
        if(Teams.Length > 2):
            if(TeamCollection.GetAgents[Teams[2]].Length = 0):
                if(not eliminatedTeams.Find[Teams[2]]):
                    if(set eliminatedTeams += array{Teams[2]}):
                        Print("Green Team is Eliminated!")
                        HUDMessage.SetText(ScoreMessage("Green Team is Eliminated!"))
                        HUDMessage.Show()

        # チーム4（Yellow）人数確認
        if(Teams.Length > 3):
            if(TeamCollection.GetAgents[Teams[3]].Length = 0):
                if(not eliminatedTeams.Find[Teams[3]]):
                    if(set eliminatedTeams += array{Teams[3]}):
                        Print("Yellow Team is Eliminated!")
                        HUDMessage.SetText(ScoreMessage("Yellow Team is Eliminated!"))
                        HUDMessage.Show()



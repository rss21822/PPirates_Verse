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

# Pilfering Pirates - Main Game Rule Device
game_rule_device := class(creative_device):
    # References to display devices for Deathmatch and Infection modes
    @editable
    TeamScoreDisplay : team_score_display_device = team_score_display_device{}
    @editable
    InfectionDisplay : infection_mode_display_device = infection_mode_display_device{}

    # Ship props for each team (excluding Team 1/Red)
    @editable
    Ship2 : creative_prop = creative_prop{}
    @editable
    Ship3 : creative_prop = creative_prop{}
    @editable
    Ship4 : creative_prop = creative_prop{}

    # Teleporter devices for each team's ship (used for spawning/respawning)
    @editable
    player_teleportor_team1 : []teleporter_device  = array{}
    @editable
    player_teleportor_team2 : []teleporter_device  = array{}
    @editable
    player_teleportor_team3 : []teleporter_device  = array{}
    @editable
    player_teleportor_team4 : []teleporter_device  = array{}

    # Class and team selector devices for team switching (used in Infection mode)
    @editable
    class_selector1 : class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    class_selector2 : class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    class_selector3 : class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    class_selector4 : class_and_team_selector_device = class_and_team_selector_device{}

    var Teams:[]team = array{}

    # Map of players to their current teams
    var players_and_teams : [player]team = map{}
    # Map of teams to their player counts
    var teams_playerCount_length : [team]int = map{}
    # Array tracking which teams have been eliminated (Infection mode)
    var eliminatedTeams : []team = array{}

    # Infection mode state flags
    var IsInfectionMode : logic = false
    var PlayerAddedSubscribed : logic = false
    var InfectionMonitorActive : logic = false
    var InfectionGameEnded : logic = false

    # Visual effect played when a player changes teams (optional)
    @editable
    TeamChangeVFX : visual_effect_powerup_device = visual_effect_powerup_device{}

    # Vote group device for game mode selection
    @editable
    vote_group : vote_group_device = vote_group_device{}
    # Vote options (A = Deathmatch, B = Infection)
    @editable
    vote_optionA : vote_option_device = vote_option_device {}
    @editable
    vote_optionB : vote_option_device = vote_option_device {}

    # Reserved for future game modes (Mega Ships, etc.)
    #@editable
    #vote_optionC : vote_option_device = vote_option_device {}
    #@editable
    #vote_optionD : vote_option_device = vote_option_device {}

    # Team settings devices for tracking eliminations in Deathmatch mode
    @editable
    TeamOneRed : team_settings_and_inventory_device = team_settings_and_inventory_device{}
    @editable
    TeamTwoBlue : team_settings_and_inventory_device = team_settings_and_inventory_device{}

    # End game device for triggering victory
    @editable
    EndGame : end_game_device = end_game_device{}

    # Vote selection UI widget
    VoteSelectionUI : vote_selection_widget = vote_selection_widget{}
    var VoteWidgetPlayerAddedSubscribed : logic = false
    # UI devices for displaying messages and debug information
    @editable
    HUDMessage : hud_message_device = hud_message_device{}
    @editable
    TeamBalanceText : billboard_device = billboard_device{}
    @editable
    GameModeText : billboard_device = billboard_device{}

    # Localized message helpers
    ScoreMessage<localizes>(msg:string):message="{msg}"
    TeamBalanceMessage<localizes>(team1:int, team2:int, team3:int, team4:int):message="Red:{team1} Blue:{team2} Green:{team3} Yellow:{team4}"

    # Initialize game on start - collect player/team info and subscribe to vote events
    OnBegin<override>()<suspends> : void =

        vote_group.BeginVote()
        VoteSelectionUI.SetOwningDevice(Self)

        # Update Teams array with island configuration
        TeamCollection := GetPlayspace().GetTeamCollection()
        set Teams = TeamCollection.GetTeams()

        # Initialize player count for each team
        for(Team : Teams):
            if(TeamPlayers := TeamCollection.GetAgents[Team].Length):
                if(set teams_playerCount_length[Team] = TeamPlayers):
                    Print("Team initialized with {TeamPlayers} players")

        # Subscribe to vote events
        vote_optionA.WinVoteEvent.Subscribe(OnVoteASuccess)
        vote_optionB.WinVoteEvent.Subscribe(OnVoteBSuccess)
        #vote_optionC.WinVoteEvent.Subscribe(OnVoteCSuccess)
        #vote_optionD.WinVoteEvent.Subscribe(OnVoteDSuccess)

        vote_group.EndVoteEvent.Subscribe(player_teleport)
        vote_group.VoteTiedEvent.Subscribe(randam_vote_select)

    # Teleport all players to their team ships after voting ends
    player_teleport() : void =
        Print("Vote ended - Teleporting players to their team ships...")

        TeamCollection := GetPlayspace().GetTeamCollection()
        AllPlayers := GetPlayspace().GetPlayers()

        for (Player : AllPlayers):
            # Get player's team assignment
            if (PlayerTeam := TeamCollection.GetTeam[Player]):
                var TeamCount : int = Teams.Length

                if (TeamCount > 0 and PlayerTeam = Teams[0]):
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team1, "Red")
                else if (TeamCount > 1 and PlayerTeam = Teams[1]):
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team2, "Blue")
                else if (TeamCount > 2 and PlayerTeam = Teams[2]):
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team3, "Green")
                else if (TeamCount > 3 and PlayerTeam = Teams[3]):
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team4, "Yellow")
                else:
                    Print("Warning: No teleport mapping for player team.")

        Print("All players teleported to their team ships!")


    # Handle vote tie - randomly select between Vote A and B, then teleport players
    randam_vote_select() : void =
        Print("Vote tied! Randomly selecting game mode...")

        # Generate random integer 0 or 1 (Vote A or Vote B)
        RandomChoice := GetRandomInt(0, 1)

        if (RandomChoice = 0):
            # Vote A (Deathmatch) selected
            Print("Random selection: Deathmatch Mode")
            OnVoteASuccess(false)
        else:
            # Vote B (Infection) selected
            Print("Random selection: Infection Mode")
            OnVoteBSuccess(false)

        # Teleport all players
        player_teleport()

    # Teleport a player to a random teleporter device from the given array
    TeleportPlayerToRandomDevice(Player : agent, Teleporters : []teleporter_device, TeamName : string) : void =
        if (Teleporters.Length > 0):
            # Generate random index
            RandomIndex := GetRandomInt(0, Teleporters.Length - 1)

            if (SelectedTeleporter := Teleporters[RandomIndex]):
                SelectedTeleporter.Teleport(Player)
                Print("Player teleported to {TeamName} team ship (teleporter #{RandomIndex})")
            else:
                Print("Warning: Failed to get teleporter at index {RandomIndex} for {TeamName} team")
        else:
            Print("Warning: No teleporters configured for {TeamName} team")

    # Vote A: Deathmatch Mode
    OnVoteASuccess(InPlayer : ?agent) : void =
        Print("Deathmatch Mode Selected")
        GameModeText.SetText(ScoreMessage("Mode: Deathmatch"))
        set IsInfectionMode = false
        StopInfectionMonitor()
        set InfectionGameEnded = false

        InfectionDisplay.DeactivateUI()

        # Activate Deathmatch Mode UI
        TeamScoreDisplay.ActivateDeathmatchMode()

    # Vote B: Infection Mode
    OnVoteBSuccess(InPlayer : ?agent) : void =
        Print("Infection Mode Started")
        StopInfectionMonitor()
        set InfectionGameEnded = false
        GameModeText.SetText(ScoreMessage("Mode: Infection"))
        set IsInfectionMode = true

        set eliminatedTeams = array{}
        TeamScoreDisplay.ActivateInfectionMode()

        if(PlayerAddedSubscribed = false):
            GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
            set PlayerAddedSubscribed = true

        InfectionDisplay.ActivateInfectionUI()

        spawn{InitialInfectionUIUpdate()}

        AllPlayers := GetPlayspace().GetPlayers()
        for (Player : AllPlayers):
            if (FortCharacter := Player.GetFortCharacter[]):
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminatedInfection)

        HUDMessage.SetText(ScoreMessage("Infection Mode: Eliminate enemies to recruit them!"))
        HUDMessage.Show()

        StartInfectionMonitor()
    # Start monitoring infection teams for elimination/victory conditions
    StartInfectionMonitor() : void =
        if(InfectionMonitorActive = true):
            return

        set InfectionMonitorActive = true
        spawn{MonitorInfectionTeams()}

    # Stop monitoring infection teams
    StopInfectionMonitor() : void =
        if(InfectionMonitorActive = false):
            return

        set InfectionMonitorActive = false

    # Continuously monitor infection teams and check victory conditions
    MonitorInfectionTeams()<suspends> : void =
        if(IsInfectionMode = false or InfectionMonitorActive = false or InfectionGameEnded = true):
            set InfectionMonitorActive = false
            return

        UpdateInfectionUI()
        CheckEliminatedTeams()
        CheckInfectionEndCondition(false)

        Sleep(1.0)

        if(IsInfectionMode = true and InfectionMonitorActive = true and InfectionGameEnded = false):
            spawn{MonitorInfectionTeams()}
        else:
            set InfectionMonitorActive = false

    # Handle player joining mid-game during Infection mode
    OnPlayerAdded(InPlayer : player) : void =
        if(IsInfectionMode = false):
            return

        Print("New player joined the game!")

        # Subscribe to elimination event for Infection mode
        if(FortCharacter := InPlayer.GetFortCharacter[]):
            FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminatedInfection)

        # Teleport player to their team ship (with delay)
        spawn{TeleportLateJoiningPlayer(InPlayer)}
        spawn{EnsureLateJoinerUI(InPlayer)}

    # Teleport late-joining player to their team ship
    TeleportLateJoiningPlayer(InPlayer : player)<suspends> : void =
        if(IsInfectionMode = false):
            return

        Sleep(1.0)  # Wait for character spawn to complete

        TeamCollection := GetPlayspace().GetTeamCollection()
        if(PlayerTeam := TeamCollection.GetTeam[InPlayer]):
            var TeamCount : int = Teams.Length

            if (TeamCount > 0 and PlayerTeam = Teams[0]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team1, "Red")
            else if (TeamCount > 1 and PlayerTeam = Teams[1]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team2, "Blue")
            else if (TeamCount > 2 and PlayerTeam = Teams[2]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team3, "Green")
            else if (TeamCount > 3 and PlayerTeam = Teams[3]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team4, "Yellow")
            else:
                Print("Warning: No teleport mapping for late joining player team.")

    # Ensure late joiner UI is properly updated
    EnsureLateJoinerUI(InPlayer : player)<suspends> : void =
        Sleep(0.6)
        if(IsInfectionMode = false):
            return

        UpdateInfectionUI()
        CheckEliminatedTeams()
        CheckInfectionEndCondition(false)


    # Vote C: Reserved for future game mode (Mega Ships)
    <#
    OnVoteCSuccess(InPlayer : ?agent) : void =
        Print("Mega Ships Mode Selected")
        GameModeText.SetText(ScoreMessage("Mode: Mega Ships"))
        set IsInfectionMode = false
    #>
    # Vote D: Reserved for future game mode
    <#
    OnVoteDSuccess(InPlayer : ?agent) : void =
        Print("Deathmatch Mode Selected")
        GameModeText.SetText(ScoreMessage("Mode: Deathmatch"))
        set IsInfectionMode = false
    #>

    # Initial UI update with delay to ensure team counts are accurate
    InitialInfectionUIUpdate()<suspends> : void =
        Sleep(0.5)
        UpdateInfectionUI()

    # Handle player elimination in Infection mode
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

                        # Only process eliminations between different teams
                        if(EliminatedPlayerTeam <> EliminatorPlayerTeam):
                            Print("Team change: Player moving to new team")

                            # Execute team change
                            PerformTeamChange(EliminatedAgent, EliminatorPlayerTeam)

                            # Notify player of team change
                            if(AfterEliminatedPlayer := player[EliminatedAgent]):
                                ShowTeamChangeNotification(AfterEliminatedPlayer, EliminatorPlayerTeam)

                            # Infection mode: Teleport to new team's ship
                            spawn{TeleportToNewTeamShip(EliminatedAgent, EliminatorPlayerTeam)}

                            # Update UI with delay (after team change completes)
                            spawn{DelayedInfectionUIUpdate()}
                        else:
                            # Same team elimination (friendly fire)
                            Print("Friendly fire detected - no team change")

        # Check for end conditions
        CheckInfectionEndCondition(EliminatorPlayer)

        # Check for eliminated teams
        CheckEliminatedTeams()

    # Delayed UI update (after team change completes)
    DelayedInfectionUIUpdate()<suspends> : void =
        Sleep(0.3)
        UpdateInfectionUI()

    # Infection mode: Teleport player to new team's ship after team change
    TeleportToNewTeamShip(Agent : agent, NewTeam : team)<suspends> : void =
        if(IsInfectionMode = false):
            return

        # Wait for team change to complete
        Sleep(0.5)

        var TeamName : string = "Unknown"
        var TargetTeleporters : []teleporter_device = array{}

        # Select teleporter array based on new team
        var TeamCount : int = Teams.Length

        if (TeamCount > 0 and NewTeam = Teams[0]):
            set TargetTeleporters = player_teleportor_team1
            set TeamName = "Red"
        else if (TeamCount > 1 and NewTeam = Teams[1]):
            set TargetTeleporters = player_teleportor_team2
            set TeamName = "Blue"
        else if (TeamCount > 2 and NewTeam = Teams[2]):
            set TargetTeleporters = player_teleportor_team3
            set TeamName = "Green"
        else if (TeamCount > 3 and NewTeam = Teams[3]):
            set TargetTeleporters = player_teleportor_team4
            set TeamName = "Yellow"
        else:
            Print("Warning: No teleporters configured for the requested team.")
            return

        # Teleport to random teleporter
        TeleportPlayerToRandomDevice(Agent, TargetTeleporters, TeamName)
        Print("Infection: Player teleported to {TeamName} team ship after team change")

    # Update Infection UI with current team counts
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

        # Update InfectionDisplay (important!)
        InfectionDisplay.UpdateTeamCounts(Team1Count, Team2Count, Team3Count, Team4Count)

        # Update debug Billboard
        TeamBalanceText.SetText(TeamBalanceMessage(Team1Count, Team2Count, Team3Count, Team4Count))

    # Execute team change using class selector device
    PerformTeamChange(Agent : agent, NewTeam : team) : void =
        var TeamCount : int = Teams.Length

        if (TeamCount > 0 and NewTeam = Teams[0]):
            class_selector1.ChangeTeam(Agent)
            Print("Player joined Red Team")
        else if (TeamCount > 1 and NewTeam = Teams[1]):
            class_selector2.ChangeTeam(Agent)
            Print("Player joined Blue Team")
        else if (TeamCount > 2 and NewTeam = Teams[2]):
            class_selector3.ChangeTeam(Agent)
            Print("Player joined Green Team")
        else if (TeamCount > 3 and NewTeam = Teams[3]):
            class_selector4.ChangeTeam(Agent)
            Print("Player joined Yellow Team")
        else:
            Print("Warning: Unable to change to requested team - team not configured.")

    # Show notification to player when they change teams
    ShowTeamChangeNotification(Player : player, NewTeam : team) : void =
        var TeamName : string = "Unknown"
        var TeamCount : int = Teams.Length

        if (TeamCount > 0 and NewTeam = Teams[0]):
            set TeamName = "Red"
        else if (TeamCount > 1 and NewTeam = Teams[1]):
            set TeamName = "Blue"
        else if (TeamCount > 2 and NewTeam = Teams[2]):
            set TeamName = "Green"
        else if (TeamCount > 3 and NewTeam = Teams[3]):
            set TeamName = "Yellow"
        else:
            Print("Warning: Unable to determine team name for notification.")

        NotificationMessage := ScoreMessage("You have been recruited to {TeamName} Team!")
        HUDMessage.SetText(NotificationMessage)
        HUDMessage.Show(Player)

        # Play visual effect (if configured)
        if(FortCharacter := Player.GetFortCharacter[]):
            TeamChangeVFX.Pickup(Player)

    # Check Infection end conditions (1 team remaining = victory)
    CheckInfectionEndCondition(EliminatorPlayer : ?fort_character) : void =
        if(IsInfectionMode = false):
            return

        if(InfectionGameEnded = true):
            return

        TeamCollection := GetPlayspace().GetTeamCollection()
        var ActiveTeams : int = 0
        var WinningTeam : ?team = false

        for (i := 0..3):
            if (i < Teams.Length):
                if (TeamCollection.GetAgents[Teams[i]].Length > 0):
                    set ActiveTeams += 1
                    set WinningTeam = option{Teams[i]}

        if (ActiveTeams = 0):
            Print("No active teams remain in Infection. Ending round.")
            set InfectionGameEnded = true
            set InfectionMonitorActive = false
            set IsInfectionMode = false
            return

        if (ActiveTeams = 1):
            var VictoryAgent : ?agent = false

            if (EliminatedFortCharacter := fort_character[EliminatorPlayer?], EliminatedAgent := EliminatedFortCharacter.GetAgent[]):
                set VictoryAgent = option{EliminatedAgent}
            else if (WinningTeamValue := WinningTeam?):
                if(WinningTeamAgents := TeamCollection.GetAgents[WinningTeamValue]):
                    if (WinningTeamAgents.Length > 0):
                        if (FirstAgent := WinningTeamAgents[0]):
                            set VictoryAgent = option{FirstAgent}

            if (UnwrappedVictoryAgent := VictoryAgent?):
                Print("Infection Victory! All players united in one team!")
                EndGame.Activate(UnwrappedVictoryAgent)
                set InfectionGameEnded = true
                set InfectionMonitorActive = false
                set IsInfectionMode = false
            else:
                Print("Infection victory detected, but no agent available to trigger EndGame.")
    # Check and notify when teams are eliminated (all players gone)
    CheckEliminatedTeams() : void =
        TeamCollection := GetPlayspace().GetTeamCollection()

        # Check Team 1 (Red) player count
        if(Teams.Length > 0):
            if(TeamCollection.GetAgents[Teams[0]].Length = 0):
                if(not eliminatedTeams.Find[Teams[0]]):
                    if(set eliminatedTeams += array{Teams[0]}):
                        Print("Red Team is Eliminated!")
                        HUDMessage.SetText(ScoreMessage("Red Team is Eliminated!"))
                        HUDMessage.Show()

        # Check Team 2 (Blue) player count
        if(Teams.Length > 1):
            if(TeamCollection.GetAgents[Teams[1]].Length = 0):
                if(not eliminatedTeams.Find[Teams[1]]):
                    if(set eliminatedTeams += array{Teams[1]}):
                        Print("Blue Team is Eliminated!")
                        HUDMessage.SetText(ScoreMessage("Blue Team is Eliminated!"))
                        HUDMessage.Show()

        # Check Team 3 (Green) player count
        if(Teams.Length > 2):
            if(TeamCollection.GetAgents[Teams[2]].Length = 0):
                if(not eliminatedTeams.Find[Teams[2]]):
                    if(set eliminatedTeams += array{Teams[2]}):
                        Print("Green Team is Eliminated!")
                        HUDMessage.SetText(ScoreMessage("Green Team is Eliminated!"))
                        HUDMessage.Show()

        # Check Team 4 (Yellow) player count
        if(Teams.Length > 3):
            if(TeamCollection.GetAgents[Teams[3]].Length = 0):
                if(not eliminatedTeams.Find[Teams[3]]):
                    if(set eliminatedTeams += array{Teams[3]}):
                        Print("Yellow Team is Eliminated!")
                        HUDMessage.SetText(ScoreMessage("Yellow Team is Eliminated!"))
                        HUDMessage.Show()

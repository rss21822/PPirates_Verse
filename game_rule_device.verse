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

    @editable
    BillBoard_ForDebug : billboard_device = billboard_device{}

    @editable
    ItemGranter : item_granter_device = item_granter_device{}

    # References to display devices for Deathmatch and Infection modes
    @editable
    TeamScoreDisplay : team_score_display_device = team_score_display_device{}
    @editable
    InfectionDisplay : infection_mode_display_device = infection_mode_display_device{}

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

    # Infection mode: Verse-side team player counts
    var InfectionTeamCounts : [team]int = map{}

    # Map to track initial team assignment for late joiners
    var PlayerInitialTeams : [player]team = map{}

    # Array tracking which teams have been eliminated (Infection mode)
    var eliminatedTeams : []team = array{}

    # Tracks which team has already been counted for each player when Infection is active
    var LateJoinerTrackedTeams : [player]team = map{}
    var LateJoinerActive : [player]logic = map{}

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

    # End game device for triggering victory
    @editable
    EndGame : end_game_device = end_game_device{}

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

        # Update Teams array with island configuration
        TeamCollection := GetPlayspace().GetTeamCollection()
        set Teams = TeamCollection.GetTeams()
        set InfectionTeamCounts = map{}
        set LateJoinerTrackedTeams = map{}
        set LateJoinerActive = map{}

        # Initialize player count for each team (for Deathmatch mode)
        for(Team : Teams):
            if(TeamPlayers := TeamCollection.GetAgents[Team].Length):
                if(set teams_playerCount_length[Team] = TeamPlayers):
                    Print("Team initialized with {TeamPlayers} players")

        # Subscribe to vote events
        vote_optionA.WinVoteEvent.Subscribe(OnVoteASuccess)
        vote_optionB.WinVoteEvent.Subscribe(OnVoteBSuccess)

        vote_group.EndVoteEvent.Subscribe(player_teleport)
        vote_group.VoteTiedEvent.Subscribe(randam_vote_select)

    # Teleport all players to their team ships after voting ends
    player_teleport() : void =
        Print("Vote ended - Teleporting players to their team ships with staggered delays...")
        TeamCollection := GetPlayspace().GetTeamCollection()
        AllPlayers := GetPlayspace().GetPlayers()
        for (Player : AllPlayers):
            # Get player's team assignment
            if (PlayerTeam := TeamCollection.GetTeam[Player]):
                var TeamCount : int = Teams.Length
                if (TeamCount > 0 and PlayerTeam = Teams[0]):
                    # Team 1: Immediate teleport
                    TeleportPlayerToRandomDevice(Player, player_teleportor_team1, "Red")
                else if (TeamCount > 1 and PlayerTeam = Teams[1]):
                    # Team 2: 2.0 second delay
                    spawn{DelayedTeleport(Player, player_teleportor_team2, "Blue", 4.0)}
                else if (TeamCount > 2 and PlayerTeam = Teams[2]):
                    # Team 3: 4.0 second delay
                    spawn{DelayedTeleport(Player, player_teleportor_team3, "Green", 1.0)}
                else if (TeamCount > 3 and PlayerTeam = Teams[3]):
                    # Team 4: 6.0 second delay
                    spawn{DelayedTeleport(Player, player_teleportor_team4, "Yellow", 1.0)}
                else:
                    Print("Warning: No teleport mapping for player team.")
        Print("Teleport process initiated for all teams!")

    # Delayed teleport with specified delay
    DelayedTeleport(Player : agent, Teleporters : []teleporter_device, TeamName : string, Delay : float)<suspends> : void =
        Sleep(Delay)
        TeleportPlayerToRandomDevice(Player, Teleporters, TeamName)
        Print("Delayed teleport completed for {TeamName} team after {Delay} seconds")

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
        var trial : int = 0
        if (Teleporters.Length > 0):
            # Generate random index
            RandomIndex := GetRandomInt(0, Teleporters.Length - 1)
            if (SelectedTeleporter := Teleporters[RandomIndex]):
                SelectedTeleporter.Teleport(Player)
                Print("Player teleported to {TeamName} team ship (teleporter #{RandomIndex})")

                BillBoard_ForDebug.SetText(ScoreMessage("Player teleported to {TeamName} team ship (teleporter #{RandomIndex}), trial: #{trial}"))
                BillBoard_ForDebug.ShowText()

                set trial += 1
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
        set InfectionTeamCounts = map{}
        set LateJoinerTrackedTeams = map{}
        set LateJoinerActive = map{}

        # Activate Deathmatch Mode UI
        TeamScoreDisplay.ActivateDeathmatchMode()

        # Subscribe to PlayerAdded for Deathmatch mode only
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAddedDeathmatch)

    # Handle player joining during Deathmatch mode
    OnPlayerAddedDeathmatch(InPlayer : player) : void =
        ItemGranter.GrantItem(InPlayer)

    # Handle player joining during Infection mode
    OnPlayerAddedInfection(InPlayer : player) : void =
        if(IsInfectionMode = false):
            return

        Print("Player joined during Infection mode")
        ItemGranter.GrantItem(InPlayer)

        # Subscribe to elimination event for Infection mode
        if(FortCharacter := InPlayer.GetFortCharacter[]):
            FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminatedInfection)

        # Track initial team for late joiner
        TeamCollection := GetPlayspace().GetTeamCollection()
        if(PlayerTeam := TeamCollection.GetTeam[InPlayer]):
            if(set PlayerInitialTeams[InPlayer] = PlayerTeam):
                Print("Late joiner initial team tracked")

        # Teleport player to their team ship (with delay)
        spawn{TeleportLateJoiningPlayer(InPlayer)}
        spawn{EnsureLateJoinerUI(InPlayer)}
        spawn{MonitorLateJoinerTeamChange(InPlayer)}

    # Vote B: Infection Mode
    OnVoteBSuccess(InPlayer : ?agent) : void =
        Print("Infection Mode Started")
        StopInfectionMonitor()
        set InfectionGameEnded = false
        GameModeText.SetText(ScoreMessage("Mode: Infection"))
        set IsInfectionMode = true
        set eliminatedTeams = array{}
        RefreshInfectionTeamState()

        TeamScoreDisplay.ActivateInfectionMode()

        # Subscribe to PlayerAdded/RemovedEvent for Infection mode only
        if(PlayerAddedSubscribed = false):
            GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAddedInfection)
            GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemovedInfection)
            set PlayerAddedSubscribed = true

        InfectionDisplay.ActivateInfectionUI()
        UpdateInfectionUI()
        spawn{InitialInfectionUIUpdate()}
        AllPlayers := GetPlayspace().GetPlayers()
        for (Player : AllPlayers):
            if (FortCharacter := Player.GetFortCharacter[]):
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminatedInfection)
        HUDMessage.SetText(ScoreMessage("Infection Mode: Eliminate enemies to recruit them!"))
        HUDMessage.Show()
        StartInfectionMonitor()

    RefreshInfectionTeamState() : void =
        TeamCollection := GetPlayspace().GetTeamCollection()
        set InfectionTeamCounts = map{}
        set LateJoinerTrackedTeams = map{}
        set LateJoinerActive = map{}
        set PlayerInitialTeams = map{}

        for(Team : Teams):
            var TeamSize : int = 0
            if(TeamAgents := TeamCollection.GetAgents[Team]):
                set TeamSize = TeamAgents.Length
            if(set InfectionTeamCounts[Team] = TeamSize):
                Print("Infection count initialized for team with {TeamSize} players")

        AllPlayers := GetPlayspace().GetPlayers()
        for(CurrentPlayer : AllPlayers):
            if(PlayerTeam := TeamCollection.GetTeam[CurrentPlayer]):
                if(set PlayerInitialTeams[CurrentPlayer] = PlayerTeam){}
                if(set LateJoinerTrackedTeams[CurrentPlayer] = PlayerTeam){}
                if(set LateJoinerActive[CurrentPlayer] = true){}

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


    # Monitor late joiner team changes (for eliminated team reassignment)
    MonitorLateJoinerTeamChange(InPlayer : player)<suspends> : void =
        Sleep(0.5)
        if(IsInfectionMode = false):
            return
        TeamCollection := GetPlayspace().GetTeamCollection()
        if(CurrentTeam := TeamCollection.GetTeam[InPlayer]):
            var CountsChanged : logic = false
            var AlreadyCounted : logic = false

            if(ActiveState := LateJoinerActive[InPlayer]):
                if(ActiveState = true):
                    set AlreadyCounted = true

            if(AlreadyCounted = true):
                if(TrackedTeam := LateJoinerTrackedTeams[InPlayer]):
                    if(TrackedTeam <> CurrentTeam):
                        Print("Late joiner team change detected")
                        if(TrackedCount := InfectionTeamCounts[TrackedTeam]):
                            if(TrackedCount > 0):
                                if(set InfectionTeamCounts[TrackedTeam] = TrackedCount - 1):
                                    Print("Decremented previous team count for late joiner")
                                    set CountsChanged = true
                        if(NewTeamCount := InfectionTeamCounts[CurrentTeam]):
                            if(set InfectionTeamCounts[CurrentTeam] = NewTeamCount + 1):
                                Print("Incremented new team count for late joiner")
                                set CountsChanged = true
                        else:
                            if(set InfectionTeamCounts[CurrentTeam] = 1):
                                Print("Initialized new team count for late joiner")
                                set CountsChanged = true
                        if(set LateJoinerTrackedTeams[InPlayer] = CurrentTeam){}
                        if(set PlayerInitialTeams[InPlayer] = CurrentTeam){}
                        if(set LateJoinerActive[InPlayer] = true){}
            else:
                # First time we see this player during Infection - add them to the current team count
                if(CurrentCount := InfectionTeamCounts[CurrentTeam]):
                    if(set InfectionTeamCounts[CurrentTeam] = CurrentCount + 1):
                        Print("Registered late joiner on current team")
                        set CountsChanged = true
                else:
                    if(set InfectionTeamCounts[CurrentTeam] = 1):
                        Print("Initialized team count for new late joiner")
                        set CountsChanged = true
                if(set LateJoinerTrackedTeams[InPlayer] = CurrentTeam){}
                if(set PlayerInitialTeams[InPlayer] = CurrentTeam){}
                if(set LateJoinerActive[InPlayer] = true){}

            if(CountsChanged = true):
                spawn{DelayedInfectionUIUpdate()}

            if(IsInfectionMode = true):
                spawn{MonitorLateJoinerTeamChange(InPlayer)}

    # Handle player leaving during Infection mode
    OnPlayerRemovedInfection(InPlayer : player) : void =
        if(IsInfectionMode = false):
            return
        Print("Player left the game during Infection mode")
        TeamCollection := GetPlayspace().GetTeamCollection()
        if(PlayerTeam := TeamCollection.GetTeam[InPlayer]):
            if(CurrentCount := InfectionTeamCounts[PlayerTeam]):
                if(set InfectionTeamCounts[PlayerTeam] = CurrentCount - 1):
                    Print("Decremented team count for leaving player")
                    spawn{DelayedInfectionUIUpdate()}
            if(set LateJoinerActive[InPlayer] = false){}

    # Teleport late-joining player to their team ship
    TeleportLateJoiningPlayer(InPlayer : player)<suspends> : void =
        if(IsInfectionMode = false):
            return
        Sleep(1.0)  # Wait for character spawn to complete
        TeamCollection := GetPlayspace().GetTeamCollection()
        if(PlayerTeam := TeamCollection.GetTeam[InPlayer]):
            var TargetTeam : team = PlayerTeam

            if(eliminatedTeams.Find[PlayerTeam]):
                LeastTeamOption := FindLeastPopulatedActiveTeam()
                if(LeastTeam := LeastTeamOption?):
                    if(LeastTeam <> PlayerTeam):
                        if(FortCharacter := InPlayer.GetFortCharacter[]):
                            if(Agent := FortCharacter.GetAgent[]):
                                Print("Reassigning late joiner from eliminated team")
                                PerformTeamChange(Agent, LeastTeam)
                                ShowTeamChangeNotification(InPlayer, LeastTeam)
                                set TargetTeam = LeastTeam
                                spawn{DelayedInfectionUIUpdate()}
                            else:
                                Print("Warning: Unable to acquire agent for late joiner reassignment.")
                                return
                        else:
                            Print("Warning: Unable to acquire character for late joiner reassignment.")
                            return
                    else:
                        set TargetTeam = LeastTeam
                else:
                    Print("Warning: No active Infection team available for late joiner reassignment.")
                    return
            var TeamCount : int = Teams.Length

            if (TeamCount > 0 and TargetTeam = Teams[0]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team1, "Red")
            else if (TeamCount > 1 and TargetTeam = Teams[1]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team2, "Blue")
            else if (TeamCount > 2 and TargetTeam = Teams[2]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team3, "Green")
            else if (TeamCount > 3 and TargetTeam = Teams[3]):
                TeleportPlayerToRandomDevice(InPlayer, player_teleportor_team4, "Yellow")
            else:
                Print("Warning: No teleport mapping for late joining player team.")


    FindLeastPopulatedActiveTeam() : ?team =
        TeamCollection := GetPlayspace().GetTeamCollection()
        var BestTeam : ?team = false
        var BestCount : int = 2147483647
        for(Team : Teams):
            if(not eliminatedTeams.Find[Team]):
                if(TeamAgents := TeamCollection.GetAgents[Team]):
                    if(TeamAgents.Length < BestCount):
                        set BestCount = TeamAgents.Length
                        set BestTeam = option{Team}
        return BestTeam

    # Ensure late joiner UI is properly updated
    EnsureLateJoinerUI(InPlayer : player)<suspends> : void =
        Sleep(0.6)
        if(IsInfectionMode = false):
            return
        UpdateInfectionUI()
        CheckEliminatedTeams()
        CheckInfectionEndCondition(false)

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

                            # Update Infection team counts: -1 from eliminated team, +1 to eliminator team
                            if(EliminatedCount := InfectionTeamCounts[EliminatedPlayerTeam]):
                                if(set InfectionTeamCounts[EliminatedPlayerTeam] = EliminatedCount - 1):
                                    Print("Decremented eliminated player's team count")
                            if(EliminatorCount := InfectionTeamCounts[EliminatorPlayerTeam]):
                                if(set InfectionTeamCounts[EliminatorPlayerTeam] = EliminatorCount + 1):
                                    Print("Incremented eliminator's team count")
                            else:
                                if(set InfectionTeamCounts[EliminatorPlayerTeam] = 1):
                                    Print("Initialized eliminator's team count")

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
        TeamCollection := GetPlayspace().GetTeamCollection()
        var TargetTeam : team = NewTeam
        if(CurrentTeam := TeamCollection.GetTeam[Agent]):
            set TargetTeam = CurrentTeam

        var TeamName : string = "Unknown"
        var TargetTeleporters : []teleporter_device = array{}

        # Select teleporter array based on resolved team
        var TeamCount : int = Teams.Length
        if (TeamCount > 0 and TargetTeam = Teams[0]):
            set TargetTeleporters = player_teleportor_team1
            set TeamName = "Red"
        else if (TeamCount > 1 and TargetTeam = Teams[1]):
            set TargetTeleporters = player_teleportor_team2
            set TeamName = "Blue"
        else if (TeamCount > 2 and TargetTeam = Teams[2]):
            set TargetTeleporters = player_teleportor_team3
            set TeamName = "Green"
        else if (TeamCount > 3 and TargetTeam = Teams[3]):
            set TargetTeleporters = player_teleportor_team4
            set TeamName = "Yellow"
        else:
            Print("Warning: No teleporters configured for the requested team.")
            return

        # Teleport to random teleporter
        TeleportPlayerToRandomDevice(Agent, TargetTeleporters, TeamName)
        Print("Infection: Player teleported to {TeamName} team ship after team change")

    # Update Infection UI with current team counts (using Verse-side data)
    UpdateInfectionUI() : void =
        var Team1Count : int = 0
        var Team2Count : int = 0
        var Team3Count : int = 0
        var Team4Count : int = 0

        # Get counts from Verse-side InfectionTeamCounts map
        if(Teams.Length > 0):
            if(Count := InfectionTeamCounts[Teams[0]]):
                set Team1Count = Count
        if(Teams.Length > 1):
            if(Count := InfectionTeamCounts[Teams[1]]):
                set Team2Count = Count
        if(Teams.Length > 2):
            if(Count := InfectionTeamCounts[Teams[2]]):
                set Team3Count = Count
        if(Teams.Length > 3):
            if(Count := InfectionTeamCounts[Teams[3]]):
                set Team4Count = Count

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



using { /Fortnite.com/UI }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Colors/NamedColors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { RankingSystem }

<#[]=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=[]

    ██╗  ██╗ █████╗  ██████╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ 
    ██║ ██╔╝██╔══██╗██║   ██╗██╔══██╗██║   ██║████╗  ██║╚════██╗
    █████╔╝ ███████║██║   ██║██████╔╝██║   ██║██╔██╗ ██║ █████╔╝
    ██╔═██╗ ██╔══██║██║   ██║██╔══██╗██║   ██║██║╚██╗██║ ╚═══██╗
    ██║  ██╗██║  ██║╚██████╔╝██║  ██║╚██████╔╝██║ ╚████║██████╔╝
    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝    Twitter @oru7_ka

[]=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=[]#>

#ランキング比較データ
PlayerDatas:= class():
    var Player : agent
    var Point : int = 0

Ranking_System := class(creative_device):

    @editable PlayerData : RankManager = RankManager{} #ランクポイント比較のため

    @editable Rank_BP : []creative_prop = array{} #ランク表示BP
    @editable PlayerRef_Name : []player_reference_device = array{} #名前表示プレイヤー参照
    @editable BillBoard_Kill : []billboard_device = array{} #キル数表示ビルボード

    IntText<localizes>(Text_:int): message = "{Text_}" #キル数をビルボードに表示
    StringText<localizes>(Text_:string): message = "{Text_}" #キル数をビルボードに表示

    OnBegin<override>()<suspends>:void=
        RankingReload() #ゲーム開始時にRankingReloadを起動

    RankingReload()<suspends>:void=
        var Num : int = 0
        loop:
            set Num = 0
            Sleep(0.35) #ここの値は何でも可、ラグいようなら0.3や0.5に落としてみてください
            var AllPoints : []PlayerDatas = array{} #ポイント管理のarray用意
            for(Player:GetPlayspace().GetPlayers()): #全員取得
                PlayerStats := PlayerData.GetPlayerStats(Player) #各プレイヤーのRanksystemにあるデータを引っ張ってくる
                set AllPoints += array{PlayerDatas{Player := Player,Point := PlayerStats.PlayerPoints}} #arrayに各プレイヤーデータを追加
            RankingPoint := RankingAllPoints(AllPoints) #各プレイヤーデータのポイントを元に比較
            for(index->R:RankingPoint): #1位から順に以下起動
                set Num += 1
                if:
                    RankProp := Rank_BP[index] #ランク表示BP
                    PlayerRef := PlayerRef_Name[index] #名前表示プレイヤー参照
                    Billboard := BillBoard_Kill[index] #キル数表示ビルボード
                then:
                    if(Player := player[R.Player]): #playerを取得
                        PlayerStats := PlayerData.GetPlayerStats(Player) #プレイヤーのRanksystemにあるデータを引っ張ってくる
                        #ランク表示BPにポイントに基づいたランクを表示
                        if(PlayerStats.PlayerPoints>=15):
                            RankProp.SetMaterial(Bronze_Rank_1_Mat)
                            if(PlayerStats.PlayerPoints>=50):
                                RankProp.SetMaterial(Bronze_Rank_2_Mat)
                            if(PlayerStats.PlayerPoints>=110):
                                RankProp.SetMaterial(Bronze_Rank_3_Mat)
                            if(PlayerStats.PlayerPoints>=210):
                                RankProp.SetMaterial(Silver_Rank_1_Mat)
                            if(PlayerStats.PlayerPoints>=360):
                                RankProp.SetMaterial(Silver_Rank_2_Mat)
                            if(PlayerStats.PlayerPoints>=560):
                                RankProp.SetMaterial(Silver_Rank_3_Mat)
                            if(PlayerStats.PlayerPoints>=810):
                                RankProp.SetMaterial(Gold_Rank_1_Mat)
                            if(PlayerStats.PlayerPoints>=1130):
                                RankProp.SetMaterial(Gold_Rank_2_Mat)
                            if(PlayerStats.PlayerPoints>=1540):
                                RankProp.SetMaterial(Gold_Rank_3_Mat)
                            if(PlayerStats.PlayerPoints>=2040):
                                RankProp.SetMaterial(Platinum_Rank_1_Mat)
                            if(PlayerStats.PlayerPoints>=2640):
                                RankProp.SetMaterial(Platinum_Rank_2_Mat)
                            if(PlayerStats.PlayerPoints>=3390):
                                RankProp.SetMaterial(Platinum_Rank_3_Mat)
                            if(PlayerStats.PlayerPoints>=4290):
                                RankProp.SetMaterial(Diamond_Rank_1_Mat)
                            if(PlayerStats.PlayerPoints>=5340):
                                RankProp.SetMaterial(Diamond_Rank_2_Mat)
                            if(PlayerStats.PlayerPoints>=6590):
                                RankProp.SetMaterial(Diamond_Rank_3_Mat)
                            if(PlayerStats.PlayerPoints>=10390):
                                RankProp.SetMaterial(Elite_Rank_Mat)
                            if(PlayerStats.PlayerPoints>=13390):
                                RankProp.SetMaterial(Champion_Rank_Mat)
                            if(PlayerStats.PlayerPoints>=18390):
                                RankProp.SetMaterial(Unreal_Rank_Mat)
                        else:
                            RankProp.SetMaterial(Unknown_Rank_Graphic_Mat)
                        PlayerRef.Register(Player) #プレイヤーの名前をプレイヤー参照にセット
                        Billboard.SetText(IntText(PlayerStats.PlayerKills)) #プレイヤーのキル数をキル数表示ビルボードにセット
            for(t:=Num.. 16-1):
                if:
                    RankProp := Rank_BP[t] #ランク表示BP
                    PlayerRef := PlayerRef_Name[t] #名前表示プレイヤー参照
                    Billboard := BillBoard_Kill[t] #キル数表示ビルボード
                then:
                    RankProp.SetMaterial(RankBP_Material)
                    PlayerRef.Clear()
                    Billboard.SetText(StringText(""))

    #比較システム
    RankingAllPoints(Num:[]PlayerDatas):[]PlayerDatas=
        var PointArray : []PlayerDatas = Num
        for(t1:=0..PointArray.Length-1):
            for(t2 := 0..PointArray.Length-t1-2):
                if(R1 := PointArray[t2],R2 := PointArray[t2+1]):
                    if(R1.Point<R2.Point):
                        if:
                            set PointArray[t2] = R2
                            set PointArray[t2+1] = R1
        return PointArray
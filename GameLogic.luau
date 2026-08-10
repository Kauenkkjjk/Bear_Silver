local replicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local AfkModule = require(game.ServerScriptService:WaitForChild("AfkModule"))
local MissionProgressManager = require(replicatedStorage:WaitForChild("MissionProgressManager"))
local afkEvent = game.ReplicatedStorage:FindFirstChild("AfkEvent")

local bear = nil


local function transitionLighting(targetProperties, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tween = TweenService:Create(Lighting, tweenInfo, targetProperties)
	tween:Play()
	return tween
end

local function setPlayersAnchored(status)
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team == game.Teams.Survivors or player:FindFirstChild("IsBear") then
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				char.HumanoidRootPart.Anchored = status
			end
		end
	end
end

afkEvent.OnServerEvent:Connect(function(player, isAfk)
	local afkVal = player:FindFirstChild("Afk")
	if not afkVal then
		afkVal = Instance.new("BoolValue")
		afkVal.Name = "Afk"
		afkVal.Parent = player
	end
	afkVal.Value = isAfk
	AfkModule.AlternarAfk(player, isAfk)
end)

game.Players.PlayerAdded:Connect(function(player)
	local afkVal = Instance.new("BoolValue")
	afkVal.Name = "Afk"
	afkVal.Value = false
	afkVal.Parent = player
end)

Players.PlayerRemoving:Connect(function(player)
	if bear and player == bear then
		bear = nil
		replicatedStorage.StopGame.Value = true
	end

	local survivorsFolder = replicatedStorage:FindFirstChild("SurvivorsLeft")
	if survivorsFolder then
		local entry = survivorsFolder:FindFirstChild(player.Name)
		if entry then
			entry:Destroy()
		end
	end
end)

local endGameEvent = replicatedStorage:FindFirstChild("EndGame")
if endGameEvent then
	endGameEvent.OnServerEvent:Connect(function()
		replicatedStorage.StopGame.Value = true
	end)
end

local function digital_format(n)
	return string.format("%d:%02d", math.floor(n/60), n%60)
end

function teleport(Player, part)
	if Player and part then
		task.spawn(function()
			local char = Player.Character or Player.CharacterAdded:Wait()
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				for i = 1, 10 do
					hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
					task.wait(0.2)
					if (hrp.Position - part.Position).Magnitude < 10 then break end
				end
			end
		end)
	end
end

function intermissionTimer(Name, Time)
	for i = Time, 0, -1 do
		game.ReplicatedStorage.UpStatus.Value = digital_format(i)
		game.ReplicatedStorage.DownStatus.Value = Name
		wait(1)
	end
end

function sigma(puz, tim)
	puz = puz - 1
	tim = tim - -30
	task.wait(0.01)
end

local funy = game.Workspace:FindFirstChild("MapVouting")
if not funy then
	warn("MapVouting folder not found in Workspace!")
	return
end

local sss = game.ServerScriptService
local teams = game.Teams

local TimeForRound = 0
local currentPuzzles = 0

local puzzleDone = game.ReplicatedStorage:FindFirstChild("PuzzleDone")
local roundTimeDropEvent = game.ReplicatedStorage:FindFirstChild("RoundTimeDrop")
if puzzleDone then
	puzzleDone.OnServerEvent:Connect(function()
		local oldTime = TimeForRound
		TimeForRound = TimeForRound - 30
		currentPuzzles = currentPuzzles + 1
		if roundTimeDropEvent then
			roundTimeDropEvent:FireAllClients(TimeForRound, oldTime)
		end
	end)
end

local updateBearChanceEvent = game.ReplicatedStorage:FindFirstChild("UpdateBearChance")
local roundLightEvent = game.ReplicatedStorage:FindFirstChild("RoundLightEvent")
local playerDiedEvent = game.ReplicatedStorage:FindFirstChild("PlayerDied")

local SantaBossDefeatedEvent = game.ReplicatedStorage:FindFirstChild("SantaBossDefeated")
if SantaBossDefeatedEvent then
	SantaBossDefeatedEvent.OnServerEvent:Connect(function()
		game.ReplicatedStorage.StopGame.Value = true
	end)
end

local function getOrCreateTotalSurvivorsValue()
	local val = game.ReplicatedStorage:FindFirstChild("TotalSurvivors")
	if not val then
		val = Instance.new("IntValue")
		val.Name = "TotalSurvivors"
		val.Parent = game.ReplicatedStorage
	end
	return val
end

local function getOrCreateCurrentPuzzlesValue()
	local val = game.ReplicatedStorage:FindFirstChild("CurrentPuzzles")
	if not val then
		val = Instance.new("IntValue")
		val.Name = "CurrentPuzzles"
		val.Parent = game.ReplicatedStorage
		val.Value = 0
	end
	return val
end

local function hideMapNames()
	for i = 1, 3 do
		local votingObj = funy:FindFirstChild("MapVoting"..i)
		if votingObj and votingObj:FindFirstChild("Part") and votingObj.Part:FindFirstChild("MapVotingGui") then
			local gui = votingObj.Part.MapVotingGui
			if gui:FindFirstChild("MapName") then
				gui.MapName.Text = ""
			end
		end
	end
end

local function removeAllTools(player)
	for i, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end
	if player.Character then
		for i, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end
	end
end

local function hideStaminaSprintUI(player)
	if player:FindFirstChild("PlayerGui") then
		local gui = player.PlayerGui:FindFirstChild("StaminaNHealthGui")
		if gui then
			gui:Destroy()
		end
	end
end

local function triggerKillEffect(player)
	if not player or not player.Character then return end

	if player.Team == game.Teams.Survivors and bear then
		MissionProgressManager.UpdateProgress(bear, "Kill", 1)
	end

	local effectName = "Default"
	if player:FindFirstChild("EquippedKillEffect") then
		effectName = player.EquippedKillEffect.Value
	end

	local modulesFolder = game.ReplicatedStorage:FindFirstChild("Modules")
	if modulesFolder then
		local ragdollModule = modulesFolder:FindFirstChild("RagdollModule")
		if ragdollModule and ragdollModule:IsA("ModuleScript") then
			local ragdoll = require(ragdollModule)
			if ragdoll and ragdoll.ApplyEffect then
				ragdoll.ApplyEffect(player.Character)
			end
		end
	end

	if effectName and effectName ~= "Default" then
		local effectsFolder = game.ReplicatedStorage:FindFirstChild("KillEffects")
		if effectsFolder then
			local effectModule = effectsFolder:FindFirstChild(effectName .. "Module")
			if effectModule and effectModule:IsA("ModuleScript") then
				local effect = require(effectModule)
				if effect and effect.ApplyEffect then
					effect.ApplyEffect(player.Character)
				end
			end
		end
	end
end

local function setupKillEffectForPlayer(player)
	if not player then return end
	local function connectHumanoid(humanoid)
		if humanoid then
			humanoid.Died:Connect(function()
				triggerKillEffect(player)
			end)
		end
	end
	if player.Character then
		connectHumanoid(player.Character:FindFirstChild("Humanoid"))
	end
	player.CharacterAdded:Connect(function(char)
		connectHumanoid(char:FindFirstChild("Humanoid"))
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	setupKillEffectForPlayer(p)
end
Players.PlayerAdded:Connect(setupKillEffectForPlayer)
Players.PlayerAdded:Connect(setupKillEffectForPlayer)

local function setLightingForMap(mapName)
	if mapName == "Artic Valley" or mapName == "The Final Hour"then
		transitionLighting({ClockTime = 14}, 2)
	else
		transitionLighting({ClockTime = 0}, 2)
	end
end

local function resetBearPlayer(bear)
	if bear and bear:FindFirstChild("IsBear") then
		bear.IsBear:Destroy()
	end
	if bear and bear.Character then
		if bear.Character.Parent == workspace then
			bear.Character:Destroy()
		end
		bear:LoadCharacter()
	end
end

local SurvivorLight = nil
local survivorLightModule = game.ReplicatedStorage:FindFirstChild("Modules"):FindFirstChild("SurvivorLight")
if survivorLightModule and survivorLightModule:IsA("ModuleScript") then
	SurvivorLight = require(survivorLightModule)
else
	warn("SurvivorLight module not found")
end

local function setupSurvivorLightForPlayer(player)
	local function updateLight()
		if player.Character then
			SurvivorLight.AddLightToSurvivor(player.Character)
		end
	end
	player.CharacterAdded:Connect(function(char)
		SurvivorLight.AddLightToSurvivor(char)
	end)
	if player.Character then
		SurvivorLight.AddLightToSurvivor(player.Character)
	end
	if player:GetPropertyChangedSignal("Team") then
		player:GetPropertyChangedSignal("Team"):Connect(updateLight)
	end
end

for _, player in pairs(Players:GetPlayers()) do
	setupSurvivorLightForPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
	setupSurvivorLightForPlayer(player)
end)


local SurvivorsBadgeId = nil
local BearBadgeId = nil
local SurvivorsBadgeValue = script:FindFirstChild("SurvivorsBadge")
if SurvivorsBadgeValue then
	SurvivorsBadgeId = SurvivorsBadgeValue.Value
end
local BearBadgeValue = script:FindFirstChild("BearBadge")
if BearBadgeValue then
	BearBadgeId = BearBadgeValue.Value
end

local function getActivePlayersCount()
	local active = 0
	for _, p in pairs(Players:GetPlayers()) do
		local afk = p:FindFirstChild("Afk")
		if not afk or afk.Value == false then
			active = active + 1
		end
	end
	return active
end

while wait() do
	game.ReplicatedStorage.DownStatus.Value = 'Game Requires At Least 2 Players To Begin, Invite Friends!'
	game.ReplicatedStorage.UpStatus.Value = "00:00"
	bear = nil

	local songs = workspace:FindFirstChild("Songs")
	if not songs then
		warn("Songs folder not found in Workspace!")
		break
	end
	local songList = songs:GetChildren()
	if #songList == 0 then
		warn("No songs found in Songs folder!")
		break
	end
	local randomS = Random.new()
	local song = songList[randomS:NextInteger(1, #songList)]
	song:Play()

	repeat wait() until getActivePlayersCount() >= 2

	intermissionTimer("Intermission", 10)

	if getActivePlayersCount() < 2 then
		if song then song:Stop() end
		continue
	end

	if not game.ReplicatedStorage:FindFirstChild("MapVoting") then
		local mapVotingFolder = Instance.new("Folder")
		mapVotingFolder.Name = "MapVoting"
		mapVotingFolder.Parent = game.ReplicatedStorage
	end
	for i, v in game.ReplicatedStorage.MapVoting:GetChildren() do
		v:Destroy()
	end

	game.ReplicatedStorage.IsMapVoting.Value = true
	for i, player in pairs(game.Players:GetPlayers()) do
		local MapVotingValue = Instance.new("IntValue")
		MapVotingValue.Parent = game.ReplicatedStorage.MapVoting
		MapVotingValue.Name = player.Name
		MapVotingValue.Value = 0
	end

	local mapsFolder = game.ReplicatedStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("Maps folder not found in ReplicatedStorage!")
		break
	end
	local maps = mapsFolder:GetChildren()

	local keysTable = {}
	for i, map in pairs(maps) do
		table.insert(keysTable, map)
	end

	if #keysTable < 3 then
		warn("Not enough maps to vote on! At least 3 maps required.")
		game.ReplicatedStorage.DownStatus.Value = "Not enough maps for voting!"
		wait(1)
		continue
	end

	local randomKey1 = math.random(1, #keysTable)
	local mapChosen1 = keysTable[randomKey1]

	local randomKey2, mapChosen2
	repeat
		randomKey2 = math.random(1, #keysTable)
		mapChosen2 = keysTable[randomKey2]
	until mapChosen2 ~= mapChosen1

	local randomKey3, mapChosen3
	repeat
		randomKey3 = math.random(1, #keysTable)
		mapChosen3 = keysTable[randomKey3]
	until mapChosen3 ~= mapChosen1 and mapChosen3 ~= mapChosen2

	local function safeSetMapVotingGui(votingObj, mapObj)
		if votingObj and votingObj:FindFirstChild("Part") and votingObj.Part:FindFirstChild("MapVotingGui") then
			local gui = votingObj.Part.MapVotingGui
			if gui:FindFirstChild("MapImage") and gui:FindFirstChild("MapName") and mapObj and mapObj:FindFirstChild("MapVotingStuff") and mapObj.MapVotingStuff:FindFirstChild("MapImage") then
				gui.MapImage.Image = mapObj.MapVotingStuff.MapImage.Texture
				gui.MapName.Text = mapObj.Name
			else
				gui.MapImage.Image = ""
				gui.MapName.Text = ""
			end
		end
	end

	safeSetMapVotingGui(funy:FindFirstChild("MapVoting1"), mapChosen1)
	safeSetMapVotingGui(funy:FindFirstChild("MapVoting2"), mapChosen2)
	safeSetMapVotingGui(funy:FindFirstChild("MapVoting3"), mapChosen3)

	intermissionTimer('Map Voting...', 8)

	if getActivePlayersCount() < 2 then
		game.ReplicatedStorage.IsMapVoting.Value = false
		if song then song:Stop() end
		continue
	end

	game.ReplicatedStorage.IsMapVoting.Value = false

	hideMapNames()

	local one = 0
	local two = 0
	local three = 0

	for i, vote in (game.ReplicatedStorage.MapVoting:GetChildren()) do
		if vote.Value == 1 then
			one = one + 1
		elseif vote.Value == 2 then
			two = two + 1
		else
			three = three + 1
		end
	end

	local highestVoted

	if one >= two and one >= three then
		highestVoted = mapChosen1
	elseif two >= one and two >= three then
		highestVoted = mapChosen2
	else
		highestVoted = mapChosen3
	end

	script.MostVotedMap.Value = highestVoted.Name
	print("GameLogic: Selected map - " .. script.MostVotedMap.Value)
	if song then
		pcall(function() song:Stop() end)
	end

	local MapTemplate = game.ReplicatedStorage.Maps:FindFirstChild(script.MostVotedMap.Value)
	if not MapTemplate then
		warn("Selected map not found in ReplicatedStorage.Maps: " .. tostring(script.MostVotedMap.Value))
		break
	end

	local Map = MapTemplate:Clone()
	Map.Parent = workspace

	repeat task.wait() until workspace:FindFirstChild(Map.Name)
	task.wait(1.5)

	local function safeResetMapVotingGui(votingObj)
		if votingObj and votingObj:FindFirstChild("Part") and votingObj.Part:FindFirstChild("MapVotingGui") then
			local gui = votingObj.Part.MapVotingGui
			if gui:FindFirstChild("MapImage") then
				gui.MapImage.Image = ""
			end
			if gui:FindFirstChild("MapName") then
				gui.MapName.Text = ""
			end
		end
	end

	safeResetMapVotingGui(funy:FindFirstChild("MapVoting1"))
	safeResetMapVotingGui(funy:FindFirstChild("MapVoting2"))
	safeResetMapVotingGui(funy:FindFirstChild("MapVoting3"))

	game.ReplicatedStorage.MapVoting:Destroy()

	local MapFolder = Instance.new("Folder")
	MapFolder.Name = "MapVoting"
	MapFolder.Parent = game.ReplicatedStorage

	if script.MostVotedMap.Value == "Artic Valley" then
		intermissionTimer('Artic Valley Special Mode Starting!', 6)
		song:Stop()
		wait(2)
		song:Stop()

		if Map:FindFirstChild("Music") == nil then
			game.ReplicatedStorage.DownStatus.Value = Map.Name.." has no Music in it"
			task.wait(2)
			break
		end

		local mapMusic = Map.Music
		mapMusic:Play()

		local layers = game.Players:GetPlayers()
		local totalPlayers = #layers

		local roundParticipants = {}

		local totalSurvivors = 0
		for i, player in pairs(layers) do
			local isAfk = player:FindFirstChild("Afk") and player.Afk.Value
			if not isAfk then
				player.Team = teams.Survivors
				totalSurvivors = totalSurvivors + 1
				roundParticipants[player.UserId] = true
			else
				player.Team = teams.Lobby
			end
		end
		getOrCreateTotalSurvivorsValue().Value = totalSurvivors

		for i, player in pairs(layers) do
			local isAfk = player:FindFirstChild("Afk") and player.Afk.Value

			if not isAfk then
				if player:FindFirstChild("PlayerGui") then
					if player.Team == teams.Survivors then
						player.PlayerGui:WaitForChild("ShopGui").Enabled = false
						player.PlayerGui:WaitForChild("SpectateGui").Enabled = false
					end
					player.PlayerGui:WaitForChild("BearChanceGui").Enabled = false

					local shopGui = player.PlayerGui:FindFirstChild("ShopGui")
					if shopGui then
						local shopFrame = shopGui:FindFirstChild("Shop")
						if shopFrame and shopFrame:IsA("Frame") then
							shopFrame.Visible = false
						end
					end

					local inventoryGui = player.PlayerGui:FindFirstChild("InventoryGui")
					if inventoryGui then
						local inventoryFrame = inventoryGui:FindFirstChild("Inventory")
						if inventoryFrame and inventoryFrame:IsA("Frame") then
							inventoryFrame.Visible = false
						end
					end
				end

				teleport(player, Map.Spawns.PlayerSpawn)
				local val = Instance.new("RayValue")
				val.Name = player.Name
				val.Parent = game.ReplicatedStorage["SurvivorsLeft"]

				local plrGui1 = script:FindFirstChild("StaminaNHealthGui")
				if plrGui1 then
					plrGui1 = plrGui1:Clone()
					plrGui1.Parent = player.PlayerGui
				end

				local articIntro = script:FindFirstChild("ArticValleyIntroGui")
				if articIntro then
					articIntro = articIntro:Clone()
					articIntro.Parent = player.PlayerGui
				end

				local snowCannon = script:FindFirstChild("SnowCannon")
				if snowCannon then
					local gear = snowCannon:Clone()
					gear.Parent = player.Backpack
				end

				if player.Character and player.Character:FindFirstChild("Humanoid") then
					local humanoid = player.Character.Humanoid
					humanoid.Died:Connect(function()
						triggerKillEffect(player)
						if playerDiedEvent and game.ReplicatedStorage.IsMapVoting.Value == false and game.ReplicatedStorage.StopGame.Value == false then
							playerDiedEvent:FireClient(player)
						end
						player.Team = game.Teams.Lobby
					end)
				end
			end
		end

		setPlayersAnchored(true)
		transitionLighting({Ambient = Color3.new(0,0,0), OutdoorAmbient = Color3.new(0,0,0)}, 2)
		setLightingForMap(script.MostVotedMap.Value)

		game.ReplicatedStorage.DownStatus.Value = ' The Survivors Must Defeat  <font color="#00ffff">Sam</font>!'
		local Intro = script.Parent.BossFight
		Intro.Enabled = true

		local introScript = script:FindFirstChild("Introdução")
		if introScript then
			local runIntro = introScript:Clone()
			runIntro.Parent = workspace
			runIntro.Disabled = false
		end

		if Map:FindFirstChild("Lighting") then
			for i, v in pairs(game.Lighting:GetChildren()) do
				v:Destroy()
			end
			for i, v in pairs(Map.Lighting:GetChildren()) do
				local peakS = v:Clone()
				peakS.Parent = game.Lighting
			end
		end

		if script:FindFirstChild("MapIntro") then
			local mapIntros = {}
			for _, player in pairs(game.Players:GetPlayers()) do
				local introClone = script.MapIntro:Clone()
				introClone.Parent = player.PlayerGui
				if introClone:FindFirstChild("Active") and introClone.Active:IsA("LocalScript") then
					introClone.Active.Enabled = true
				end
				table.insert(mapIntros, introClone)
			end
			task.wait(6)
			for _, gui in pairs(mapIntros) do
				if gui then gui:Destroy() end
			end
		else
			task.wait(6)
		end

		setPlayersAnchored(false)
		transitionLighting({Ambient = Color3.fromRGB(127, 127, 127), OutdoorAmbient = Color3.fromRGB(127, 127, 127)}, 2)

		TimeForRound = 400
		local outcome = nil
		local totalPuzzles = 0
		if Map:FindFirstChild("Puzzles") then
			totalPuzzles = #Map.Puzzles:GetChildren()
		end
		local currentPuzzles = 0
		game.ReplicatedStorage.TotalPuzzles.Value = totalPuzzles
		getOrCreateCurrentPuzzlesValue().Value = 0

		local santaSamModel = game.ReplicatedStorage:FindFirstChild("Santa Sam")
		local santaSamHumanoid = nil
		if santaSamModel and santaSamModel:FindFirstChild("Boss") and santaSamModel.Boss:IsA("Humanoid") then
			santaSamHumanoid = santaSamModel.Boss
		end
		local santaSamDefeated = false
		if santaSamHumanoid then
			santaSamHumanoid.Died:Connect(function()
				santaSamDefeated = true
			end)
		end

		repeat
			game.ReplicatedStorage.DownStatus.Value =  ' The Survivors Must Defeat  <font color="#00ffff">Sam</font>!'
			game.ReplicatedStorage.UpStatus.Value =  digital_format(TimeForRound)
			TimeForRound = TimeForRound - 1

			if script:FindFirstChild("IsDone") and script.IsDone.Value == true then
				local oldTime = TimeForRound
				TimeForRound = TimeForRound - 30
				currentPuzzles = currentPuzzles + 1
				getOrCreateCurrentPuzzlesValue().Value = currentPuzzles
				script.IsDone.Value = false
				if roundTimeDropEvent then
					roundTimeDropEvent:FireAllClients(TimeForRound, oldTime)
				end
			end

			if santaSamDefeated then
				outcome = "SURVWIN"
				break
			end

			if game.ReplicatedStorage.StopGame.Value == true then 
				outcome = "ENDED"
				break
			end

			if getActivePlayersCount() < 1 then
				outcome = "ENDED"
				break
			end

			if #game.ReplicatedStorage["SurvivorsLeft"]:GetChildren() < 1 then
				outcome = "SURVWIN"
				break
			end

			wait(1)
		until TimeForRound < 1 or outcome ~= nil

		if outcome == "SURVWIN" or santaSamDefeated then
			game.ReplicatedStorage.BossRound.Value = false
			if workspace:FindFirstChild("Santa Sam") then
				workspace["Santa Sam"]:Destroy()
			end
		end

		if roundLightEvent then
			roundLightEvent:FireAllClients("end", {}, {})
		end

		if TimeForRound < 1 or outcome == "SURVWIN" then
			for i, player in pairs(game.Players:GetPlayers()) do 
				if roundParticipants[player.UserId] then
					if game.ReplicatedStorage["SurvivorsLeft"]:FindFirstChild(player.Name) then
						MissionProgressManager.UpdateProgress(player, "Win", 1)

						if player:FindFirstChild("Tokens") then
							player.Tokens.Value = player.Tokens.Value + math.random(50, 70)
						end
						if SurvivorsBadgeId then
							pcall(function()
								BadgeService:AwardBadge(player.UserId, SurvivorsBadgeId)
							end)
						end
					else
						if player:FindFirstChild("Tokens") then
							player.Tokens.Value = player.Tokens.Value + math.random(5, 25)
						end
					end
				end
			end
			task.wait(5)
		end

		local gameOverText = "Game Over;"
		if outcome == "SURVWIN" or TimeForRound < 1 then
			gameOverText = "Game Over: The Survivors failed to defeat Sam!"
		else
			gameOverText = "Game Over: The Survivors defeated Sam!"
		end
		game.ReplicatedStorage.DownStatus.Value = gameOverText

		task.wait(3)

		for i, player in pairs(game.Players:GetPlayers()) do
			player.Team = game.Teams.Lobby
			if player.Character and player:IsA("Player") then
				if not player.Character:FindFirstChildOfClass("ForceField") then
					local ff = Instance.new("ForceField")
					ff.Parent = player.Character
				end
			end
		end
		task.wait(3)
		for i, player in pairs(game.Players:GetPlayers()) do
			if player.Character and player:IsA("Player") and player.Character:FindFirstChildOfClass("ForceField") then
				player.Character:FindFirstChildOfClass("ForceField"):Destroy()
			end
		end
		wait(1)
		Map.Music:Stop()

		for i, player in pairs(game.Players:GetPlayers()) do
			if player.Character and player:IsA("Player") then
				if not player.Character:FindFirstChildOfClass("ForceField") then
					local ff = Instance.new("ForceField")
					ff.Parent = player.Character
				end
			end
		end
		task.wait(3)
		for i, player in pairs(game.Players:GetPlayers()) do
			if player.Character and player:IsA("Player") and player.Character:FindFirstChildOfClass("ForceField") then
				player.Character:FindFirstChildOfClass("ForceField"):Destroy()
			end
		end

		if roundLightEvent then
			roundLightEvent:FireAllClients("end", {}, {})
		end

		for i, player in pairs(game.Players:GetPlayers()) do
			removeAllTools(player)
			hideStaminaSprintUI(player)
			if player:FindFirstChild("PlayerGui") then
				local shopGui = player.PlayerGui:FindFirstChild("ShopGui")
				if shopGui then
					shopGui.Enabled = true
				end
				local spectateGui = player.PlayerGui:FindFirstChild("SpectateGui")
				if spectateGui then
					spectateGui.Enabled = true
				end
				local bearChanceGui = player.PlayerGui:FindFirstChild("BearChanceGui")
				if bearChanceGui then
					bearChanceGui.Enabled = true
				end
				local bearGui = player.PlayerGui:FindFirstChild("BearGui")
				if bearGui and (not player:FindFirstChild("IsBear")) then
					bearGui:Destroy()
				end
			end
		end

		task.wait(2)
		for i, player in pairs(game.Players:GetPlayers()) do
			player:LoadCharacter()
		end

		local function enableGUIsOnIntermission()
			local function enableForPlayer(player)
				if player:FindFirstChild("PlayerGui") then
					task.wait(3)
					player.PlayerGui:WaitForChild("ShopGui").Enabled = true
					player.PlayerGui:WaitForChild("SpectateGui").Enabled = true
					player.PlayerGui:WaitForChild("BearChanceGui").Enabled = true
					if player.PlayerGui:FindFirstChild("StaminaNHealthGui") then
						player.PlayerGui:WaitForChild("StaminaNHealthGui"):Destroy()
					end
					local bearGui = player.PlayerGui:FindFirstChild("BearGui")
					if bearGui and (not player:FindFirstChild("IsBear")) then
						bearGui:Destroy()
					end
				end
			end
			local function onDownStatusChanged()
				if game.ReplicatedStorage.DownStatus.Value == "Intermission" then
					for i, player in pairs(game.Players:GetPlayers()) do
						enableForPlayer(player)
					end
				end
			end
			game.ReplicatedStorage.DownStatus.Changed:Connect(onDownStatusChanged)
		end
		enableGUIsOnIntermission()

		task.wait(3)

		if game.Workspace:FindFirstChild("LobbyLighting") then
			for i, v in pairs(game.Lighting:GetChildren()) do
				v:Destroy()
			end

			for i, v in pairs(game.Workspace.LobbyLighting:GetChildren()) do
				local peakS = v:Clone()
				peakS.Parent = game.Lighting
			end
		end

		if Map:FindFirstChild("Music") then
			Map.Music:Stop()
		end
		Map:Destroy()

		if game.ReplicatedStorage:FindFirstChild("SurvivorsLeft") then
			game.ReplicatedStorage.SurvivorsLeft:Destroy()
		end
		local XD = Instance.new("Folder")
		XD.Parent = game.ReplicatedStorage
		XD.Name = "SurvivorsLeft"

		getOrCreateTotalSurvivorsValue().Value = 0

		local totalPuzzles = 0	
		local currentPuzzles = 0
		getOrCreateCurrentPuzzlesValue().Value = 0

		continue
	end

	local gamemode = "Classic"
	script.CurrentGameMode.Value = gamemode
	if gamemode == "Classic" then
		intermissionTimer('Starting Game...', 6)
		song:Stop()
		wait(2)
		song:Stop()

		if getActivePlayersCount() < 2 then
			continue
		end

		for i, player in pairs(game.Players:GetPlayers()) do
			if player.Character then
				SurvivorLight.AddLightToSurvivor(player.Character)
			end
		end

		if Map:FindFirstChild("Music") == nil then
			game.ReplicatedStorage.DownStatus.Value = Map.Name.." has no Music in it"
			task.wait(2)
			break
		end

		local mapMusic = Map.Music
		mapMusic:Play()

		local layers = {}
		for _, p in pairs(game.Players:GetPlayers()) do
			if p:FindFirstChild("Afk") and p.Afk.Value == false then
				table.insert(layers, p)
			else
				p.Team = teams.Lobby
			end
		end

		if #layers < 2 then
			warn("Not enough players to start the game")
			Map:Destroy()
			continue
		end

		local totalPlayers = #layers
		for i, player in pairs(layers) do
			local chance = 1 / totalPlayers * 100
			local bearChanceValue = player:FindFirstChild("BearChance")
			if not bearChanceValue then
				bearChanceValue = Instance.new("NumberValue")
				bearChanceValue.Name = "BearChance"
				bearChanceValue.Parent = player
			end
			bearChanceValue.Value = chance
			if updateBearChanceEvent then
				updateBearChanceEvent:FireClient(player, chance)
			end
		end

		local selcetedPlayer = layers[math.random(1, #layers)]
		bear = selcetedPlayer

		if not bear:FindFirstChild("EquippedSkin") or game.ReplicatedStorage.Skins:FindFirstChild(bear.EquippedSkin.Value) == nil then
			game.ReplicatedStorage.DownStatus.Value = bear.Name.."'s Skin ("..(bear:FindFirstChild("EquippedSkin") and bear.EquippedSkin.Value or "nil")..") doesn't exist"
			task.wait(2)
			Map:Destroy()
			continue
		end	

		character = game.ReplicatedStorage.Skins:FindFirstChild(bear.EquippedSkin.Value):Clone()
		character.Name = bear.Name
		bear.Character = character
		character.Parent = workspace

		local IsBear = Instance.new("StringValue")
		IsBear.Name = "IsBear"
		IsBear.Value = "tus bolas en azucar"
		IsBear.Parent = bear
		bear.Team = teams.Bear

		local XD = script:FindFirstChild("Script")
		if XD and bear.Character:FindFirstChild("HumanoidRootPart") then
			XD = XD:Clone()
			XD.Parent = bear.Character.HumanoidRootPart
			XD.Enabled = true
		end

		teleport(bear, Map.Spawns.BearSpawn)
		bear.CharacterAdded:Connect(function(char)
		end)

		local survivorIds = {}
		local bearIds = {}
		for i, player in pairs(game.Players:GetPlayers()) do
			if player:FindFirstChild("IsBear") then
				table.insert(bearIds, player.UserId)
			else
				table.insert(survivorIds, player.UserId)
			end
		end

		local roundParticipants = {}
		roundParticipants[bear.UserId] = true

		local totalSurvivors = 0
		for i, player in pairs(game.Players:GetPlayers()) do
			local isAfk = player:FindFirstChild("Afk") and player.Afk.Value
			if not player:FindFirstChild("IsBear") then
				if not isAfk then
					player.Team = teams.Survivors
					totalSurvivors = totalSurvivors + 1
					roundParticipants[player.UserId] = true
				else
					player.Team = teams.Lobby
				end
			end
		end
		getOrCreateTotalSurvivorsValue().Value = totalSurvivors

		for i, player in pairs(game.Players:GetPlayers()) do
			local isAfk = player:FindFirstChild("Afk") and player.Afk.Value

			if not isAfk then
				if player:FindFirstChild("PlayerGui") then
					if player.Team == teams.Survivors then
						player.PlayerGui:WaitForChild("ShopGui").Enabled = false
						player.PlayerGui:WaitForChild("SpectateGui").Enabled = false
					end
					player.PlayerGui:WaitForChild("BearChanceGui").Enabled = false

					local shopGui = player.PlayerGui:FindFirstChild("ShopGui")
					if shopGui then
						local shopFrame = shopGui:FindFirstChild("Shop")
						if shopFrame and shopFrame:IsA("Frame") then
							shopFrame.Visible = false
						end
					end

					local inventoryGui = player.PlayerGui:FindFirstChild("InventoryGui")
					if inventoryGui then
						local inventoryFrame = inventoryGui:FindFirstChild("Inventory")
						if inventoryFrame and inventoryFrame:IsA("Frame") then
							inventoryFrame.Visible = false
						end
					end
				end

				if not player:FindFirstChild("IsBear") then
					teleport(player, Map.Spawns.PlayerSpawn)
					local val = Instance.new("RayValue")
					val.Name = player.Name
					val.Parent = game.ReplicatedStorage["SurvivorsLeft"]

					local plrGui1 = script:FindFirstChild("StaminaNHealthGui")
					if plrGui1 then
						plrGui1 = plrGui1:Clone()
						plrGui1.Parent = player.PlayerGui
					end

					local plrGui = script:FindFirstChild("PlayerIntroGui")
					if plrGui then
						plrGui = plrGui:Clone()
						plrGui.Parent = player.PlayerGui
					end

					if player.Character and player.Character:FindFirstChild("Humanoid") then
						local humanoid = player.Character.Humanoid
						humanoid.Died:Connect(function()
							triggerKillEffect(player)
							if playerDiedEvent and game.ReplicatedStorage.IsMapVoting.Value == false and game.ReplicatedStorage.StopGame.Value == false then
								playerDiedEvent:FireClient(player)
							end
							player.Team = game.Teams.Lobby
						end)
					end
				else
					if player:FindFirstChild("PlayerGui") then
						local bearGui = nil
						if script:FindFirstChild("BearIntroGui") then
							bearGui = script:FindFirstChild("BearIntroGui"):Clone()
							bearGui.Parent = player.PlayerGui
						end
						if script:FindFirstChild("BearGui") then
							local bearMainGui = script:FindFirstChild("BearGui"):Clone()
							bearMainGui.Parent = player.PlayerGui
							bearMainGui.Enabled = true
						end
					end
				end
			end
		end

		setPlayersAnchored(true)
		transitionLighting({Ambient = Color3.new(0,0,0), OutdoorAmbient = Color3.new(0,0,0)}, 2)
		setLightingForMap(script.MostVotedMap.Value)

		if roundLightEvent then
			roundLightEvent:FireAllClients("start", survivorIds, bearIds)
		end

		if bear.Character and bear.Character:FindFirstChild("HumanoidRootPart") and bear.Character.HumanoidRootPart:FindFirstChild("Script") and bear.Character.HumanoidRootPart.Script:FindFirstChild("EquippedKillEffectFromPlayer") then
			if bear.Character.HumanoidRootPart.Script.EquippedKillEffectFromPlayer.Value == nil then
				local a = "Default"
				if bear:FindFirstChild("EquippedKillEffect") then
					a = bear.EquippedKillEffect.Value
				end
				bear.Character.HumanoidRootPart.Script.EquippedKillEffectFromPlayer.Value = a
			else
				if bear:FindFirstChild("EquippedKillEffect") then
					bear.Character.HumanoidRootPart.Script.EquippedKillEffectFromPlayer.Value = bear.EquippedKillEffect.Value
				end
			end
		end

		task.wait(3)

		if Map:FindFirstChild("Lighting") then
			for i, v in pairs(game.Lighting:GetChildren()) do
				v:Destroy()
			end
			for i, v in pairs(Map.Lighting:GetChildren()) do
				local peakS = v:Clone()
				peakS.Parent = game.Lighting
			end
		end

		if script:FindFirstChild("MapIntro") then
			local mapIntros = {}
			for _, player in pairs(game.Players:GetPlayers()) do
				local introClone = script.MapIntro:Clone()
				introClone.Parent = player.PlayerGui
				if introClone:FindFirstChild("Active") and introClone.Active:IsA("LocalScript") then
					introClone.Active.Enabled = true
				end
				table.insert(mapIntros, introClone)
			end
			task.wait(6)
			for _, gui in pairs(mapIntros) do
				if gui then gui:Destroy() end
			end
		else
			task.wait(6)
		end

		setPlayersAnchored(false)
		transitionLighting({Ambient = Color3.fromRGB(127, 127, 127), OutdoorAmbient = Color3.fromRGB(127, 127, 127)}, 2)

		for i, player in pairs(game.Players:GetPlayers()) do
			if not player:FindFirstChild("IsBear") then
				if player:FindFirstChild("Afk") and player.Afk.Value == false then
					local sg
					if player:FindFirstChild("EquippedSocialGear") and player.EquippedSocialGear.Value ~= "" and game.ReplicatedStorage.SocialGears:FindFirstChild(player.EquippedSocialGear.Value) then
						sg = game.ReplicatedStorage.SocialGears[player.EquippedSocialGear.Value]:Clone()
						sg.Parent = player.Backpack
					else
						if game.ReplicatedStorage.SocialGears:FindFirstChild("FlashLight") then
							sg = game.ReplicatedStorage.SocialGears.FlashLight:Clone()
							sg.Parent = player.Backpack
						end
					end
				end
			end
		end

		wait(1)

		TimeForRound = 300

		local outcome = nil

		local totalPuzzles = 0
		if Map:FindFirstChild("Puzzles") then
			totalPuzzles = #Map.Puzzles:GetChildren()
		end
		local currentPuzzles = 0

		game.ReplicatedStorage.TotalPuzzles.Value = totalPuzzles
		getOrCreateCurrentPuzzlesValue().Value = 0

		repeat
			game.ReplicatedStorage.DownStatus.Value = ' <font color="#3498db">Survivors</font> must survive <font color="#e74c3c">Bear</font> for the full Time Limit'
			game.ReplicatedStorage.UpStatus.Value =  digital_format(TimeForRound)
			TimeForRound = TimeForRound - 1

			if script:FindFirstChild("IsDone") and script.IsDone.Value == true then
				local oldTime = TimeForRound
				TimeForRound = TimeForRound - 30
				currentPuzzles = currentPuzzles + 1
				getOrCreateCurrentPuzzlesValue().Value = currentPuzzles
				script.IsDone.Value = false
				if roundTimeDropEvent then
					roundTimeDropEvent:FireAllClients(TimeForRound, oldTime)
				end
			end

			if not bear or not Players:FindFirstChild(bear.Name) then
				outcome = "BERDIED"
				break
			end

			if not bear:FindFirstChild("IsBear") then
				outcome = "BERDIED"
				break
			end

			if game.ReplicatedStorage.StopGame.Value == true then 
				outcome = "ENDED"
				break
			end

			if getActivePlayersCount() < 2 then
				outcome = "ENDED"
				break
			end

			if #game.ReplicatedStorage["SurvivorsLeft"]:GetChildren() < 1 then
				outcome = "BERWIN"
				break
			end

			wait(1)
		until TimeForRound < 1 or outcome ~= nil

		if roundLightEvent then
			roundLightEvent:FireAllClients("end", {}, {})
		end

		local gameOverText = "Game Over;"
		if outcome == "BERWIN" then
			gameOverText = "Game Over: Bear has killed all Survivors."

			if bear then
				MissionProgressManager.UpdateProgress(bear, "Win", 1)
			end

		elseif outcome == "BERDIED" or TimeForRound < 1 then
			gameOverText = "Game Over: Bear couldn't kill all Survivors in the Time Limit!"

			for _, p in pairs(game.Players:GetPlayers()) do
				if p.Team == game.Teams.Survivors and game.ReplicatedStorage.SurvivorsLeft:FindFirstChild(p.Name) then
					MissionProgressManager.UpdateProgress(p, "Win", 1)
				end
			end

		elseif outcome == "ENDED" then
			gameOverText = "Game Over: Not enough active players."
		end
		game.ReplicatedStorage.DownStatus.Value = gameOverText

		task.wait(3)

		resetBearPlayer(bear)

		if TimeForRound < 1 or outcome == "BERDIED" then
			for i, player in pairs(game.Players:GetPlayers()) do 
				if roundParticipants[player.UserId] then
					if not player:FindFirstChild("IsBear") then
						if game.ReplicatedStorage["SurvivorsLeft"]:FindFirstChild(player.Name) then
							if player:FindFirstChild("Tokens") then
								player.Tokens.Value = player.Tokens.Value + math.random(50, 70)
							end
							if SurvivorsBadgeId then
								pcall(function() BadgeService:AwardBadge(player.UserId, SurvivorsBadgeId) end)
							end
						else
							if player:FindFirstChild("Tokens") then
								player.Tokens.Value = player.Tokens.Value + math.random(5, 25)
							end
						end
					elseif player:FindFirstChild("IsBear") then
						if player:FindFirstChild("Tokens") then
							player.Tokens.Value = player.Tokens.Value + math.random(5, 25)
						end
					end
				end
			end
		elseif outcome == "BERWIN" then
			if bear and bear:FindFirstChild("Tokens") then
				bear.Tokens.Value = bear.Tokens.Value + math.random(80, 100)
			end
			if BearBadgeId and bear then
				pcall(function() BadgeService:AwardBadge(bear.UserId, BearBadgeId) end)
			end
			for i, player in pairs(game.Players:GetPlayers()) do
				if roundParticipants[player.UserId] then
					if not player:FindFirstChild("IsBear") and player:FindFirstChild("Tokens") then
						player.Tokens.Value = player.Tokens.Value + math.random(5, 25)
					end
				end
			end
			task.wait(2)
		else
			for i, player in pairs(game.Players:GetPlayers()) do
				if roundParticipants[player.UserId] then
					if player:FindFirstChild("Tokens") then
						player.Tokens.Value = player.Tokens.Value + math.random(5, 25)
					end
				end
			end
		end

		if bear and bear:FindFirstChild("IsBear") then
			bear.IsBear:Destroy()
		end

		for i, player in pairs(game.Players:GetPlayers()) do
			player.Team = game.Teams.Lobby
			if player.Character and player:IsA("Player") then
				if not player.Character:FindFirstChildOfClass("ForceField") then
					local ff = Instance.new("ForceField")
					ff.Parent = player.Character
				end
			end
		end
		task.wait(3)
		for i, player in pairs(game.Players:GetPlayers()) do
			if player.Character and player:IsA("Player") and player.Character:FindFirstChildOfClass("ForceField") then
				player.Character:FindFirstChildOfClass("ForceField"):Destroy()
			end
			if player:FindFirstChild("IsBear") then
				player.IsBear:Destroy()
			end
		end
		wait(1)
		Map.Music:Stop()

		for i, player in pairs(game.Players:GetPlayers()) do
			if player.Character and player:IsA("Player") then
				if not player.Character:FindFirstChildOfClass("ForceField") then
					local ff = Instance.new("ForceField")
					ff.Parent = player.Character
				end
			end
		end
		task.wait(3)
		for i, player in pairs(game.Players:GetPlayers()) do
			if player.Character and player:IsA("Player") and player.Character:FindFirstChildOfClass("ForceField") then
				player.Character:FindFirstChildOfClass("ForceField"):Destroy()
			end
		end

		if roundLightEvent then
			roundLightEvent:FireAllClients("end", {}, {})
		end

		transitionLighting({Ambient = Color3.fromRGB(200, 200, 200), OutdoorAmbient = Color3.fromRGB(200, 200, 200)}, 2)

		for i, player in pairs(game.Players:GetPlayers()) do
			removeAllTools(player)
			hideStaminaSprintUI(player)
			if player:FindFirstChild("PlayerGui") then
				local shopGui = player.PlayerGui:FindFirstChild("ShopGui")
				if shopGui then
					shopGui.Enabled = true
				end
				local spectateGui = player.PlayerGui:FindFirstChild("SpectateGui")
				if spectateGui then
					spectateGui.Enabled = true
				end
				local bearChanceGui = player.PlayerGui:FindFirstChild("BearChanceGui")
				if bearChanceGui then
					bearChanceGui.Enabled = true
				end
				local bearGui = player.PlayerGui:FindFirstChild("BearGui")
				if bearGui and (not player:FindFirstChild("IsBear")) then
					bearGui:Destroy()
				end
			end
			if player:FindFirstChild("IsBear") then
				player.IsBear:Destroy()
			end
		end

		task.wait(2)
		for i, player in pairs(game.Players:GetPlayers()) do
			player:LoadCharacter()
		end
		if bear then
			resetBearPlayer(bear)
		end


		local function enableGUIsOnIntermissionClassic()
			local function enableForPlayer(player)
				local playerGui = player:FindFirstChild("PlayerGui")
				if playerGui then
					task.wait(3)
					playerGui:WaitForChild("ShopGui").Enabled = true
					playerGui:WaitForChild("SpectateGui").Enabled = true
					playerGui:WaitForChild("BearChanceGui").Enabled = true
					local bearGui = playerGui:FindFirstChild("BearGui")
					if bearGui and (not player:FindFirstChild("IsBear")) then
						bearGui:Destroy()
					end
					if playerGui:FindFirstChild("StaminaNHealthGui") then
						playerGui:WaitForChild("StaminaNHealthGui"):Destroy()
					end
				end
			end
			local function onDownStatusChanged()
				if game.ReplicatedStorage.DownStatus.Value == "Intermission" then
					for i, player in pairs(game.Players:GetPlayers()) do
						enableForPlayer(player)
					end
				end
			end
			game.ReplicatedStorage.DownStatus.Changed:Connect(onDownStatusChanged)
		end
		enableGUIsOnIntermissionClassic()

		task.wait(3)

		if game.Workspace:FindFirstChild("LobbyLighting") then
			for i, v in pairs(game.Lighting:GetChildren()) do
				v:Destroy()
			end

			for i, v in pairs(game.Workspace.LobbyLighting:GetChildren()) do
				local peakS = v:Clone()
				peakS.Parent = game.Lighting
			end
		end

		if Map:FindFirstChild("Music") then
			Map.Music:Stop()
		end
		Map:Destroy()

		if game.ReplicatedStorage:FindFirstChild("SurvivorsLeft") then
			game.ReplicatedStorage.SurvivorsLeft:Destroy()
		end
		local XD = Instance.new("Folder")
		XD.Parent = game.ReplicatedStorage
		XD.Name = "SurvivorsLeft"

		getOrCreateTotalSurvivorsValue().Value = 0

		local totalPuzzles = 0	
		local currentPuzzles = 0
		getOrCreateCurrentPuzzlesValue().Value = 0
	end
end
puzzleDone.OnServerEvent:Connect(sigma)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local roomChangedEvent = remotesFolder:WaitForChild("RoomChanged")
local objectiveChangedEvent = remotesFolder:WaitForChild("ObjectiveChanged")

local config = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("DungeonConfig"))
local roomsFolder = workspace:WaitForChild(config.RoomsFolderName)
local rng = Random.new()

local playerState = {}

local function buildHudData(state)
	return {
		statsText = config.getStatsText(state),
		statsData = config.getStatsData(state),
		runComplete = state.runComplete,
		victoryText = config.getVictoryText(state),
	}
end

local function applyRewardEffect(state, reward)
	local rewardName = reward.name or "Tesouro Misterioso"
	local rewardAmount = reward.amount or 0
	local rewardEffect = reward.effect

	state.chestReward = rewardName
	state.chestRewardSummary = reward.summary or ""

	if rewardEffect == "heal" then
		local currentHp = state.playerHp or config.PlayerStartHp or config.PlayerMaxHp
		local maxHp = state.playerMaxHp or config.PlayerMaxHp
		local healedHp = math.min(maxHp, currentHp + rewardAmount)
		local restoredAmount = healedHp - currentHp

		state.playerHp = healedHp
		if restoredAmount > 0 then
			state.chestRewardSummary = string.format("+%d HP", restoredAmount)
		else
			state.chestRewardSummary = "vida cheia"
		end
		return
	end

	if rewardEffect == "coins" then
		state.coins = (state.coins or 0) + rewardAmount
		return
	end

	if rewardEffect == "damage" then
		state.bonusDamage = (state.bonusDamage or 0) + rewardAmount
		return
	end

	if rewardEffect == "defense" then
		state.bonusDefense = (state.bonusDefense or 0) + rewardAmount
		return
	end
end

local function getState(player)
	if not playerState[player] then
		playerState[player] = {
			currentRoom = "StartRoom",
			playerMaxHp = config.PlayerMaxHp,
			playerHp = config.PlayerStartHp or config.PlayerMaxHp,
			coins = 0,
			bonusDamage = 0,
			bonusDefense = 0,
			goblinHp = config.GoblinMaxHp,
			goblinDefeated = false,
			exitBossHp = config.ExitBossMaxHp,
			exitBossDefeated = false,
			chestOpened = false,
			chestReward = nil,
			chestRewardSummary = nil,
			altarUsed = false,
			altarBlessing = nil,
			runComplete = false,
		}
	end

	return playerState[player]
end

local function pushHud(player)
	local state = getState(player)
	local roomName = state.currentRoom or "StartRoom"
	local displayName = config.RoomDisplayNames[roomName] or roomName
	local objectiveText = config.getObjective(roomName, state)
	local hudData = buildHudData(state)

	roomChangedEvent:FireClient(player, displayName, objectiveText, hudData)
	objectiveChangedEvent:FireClient(player, objectiveText, hudData)
end

local function setCurrentRoom(player, roomName)
	local state = getState(player)

	if state.currentRoom == roomName then
		return
	end

	state.currentRoom = roomName
	pushHud(player)
end

local function getPlayerFromHit(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function connectRoomTrigger(roomModel)
	local trigger = roomModel:FindFirstChild(config.TriggerName, true)
	if not trigger or not trigger:IsA("BasePart") then
		warn("RoomTrigger não encontrado em " .. roomModel.Name)
		return
	end

	trigger.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if not player then
			return
		end

		setCurrentRoom(player, roomModel.Name)
	end)
	end

local function bindPrompt(roomName, markerName, callback)
	local room = roomsFolder:FindFirstChild(roomName)
	if not room then
		warn("Sala não encontrada: " .. roomName)
		return
	end

	local marker = room:FindFirstChild(markerName, true)
	if not marker then
		warn("Marcador não encontrado: " .. markerName)
		return
	end

	local prompt = marker:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		warn("ProximityPrompt não encontrado em " .. markerName)
		return
	end

	prompt.Triggered:Connect(function(player)
		callback(player, prompt)
	end)
end

local function defeatGoblin(player)
	local state = getState(player)
	if state.goblinDefeated then
		pushHud(player)
		return
	end

	state.goblinHp = math.max(0, (state.goblinHp or config.GoblinMaxHp) - 1)
	if state.goblinHp <= 0 then
		state.goblinDefeated = true
		state.coins = (state.coins or 0) + (config.GoblinCoinReward or 0)
	else
		local counterDamage = math.max(0, (config.GoblinCounterDamage or 0) - (state.bonusDefense or 0))
		if counterDamage > 0 then
			state.playerHp = math.max(1, (state.playerHp or state.playerMaxHp or config.PlayerMaxHp) - counterDamage)
		end
	end
	pushHud(player)
end

local function openChest(player)
	local state = getState(player)

	if not state.goblinDefeated then
		pushHud(player)
		return
	end

	if state.chestOpened then
		pushHud(player)
		return
	end

	local rewardPool = config.ChestRewards or {}
	if #rewardPool > 0 then
		local rewardIndex = rng:NextInteger(1, #rewardPool)
		local reward = rewardPool[rewardIndex]
		if type(reward) == "string" then
			reward = {
				name = reward,
			}
		end
		applyRewardEffect(state, reward)
	else
		state.chestReward = "um tesouro misterioso"
		state.chestRewardSummary = "efeito desconhecido"
	end
	state.chestOpened = true
	pushHud(player)
end

local function useAltar(player)
	local state = getState(player)

	if not state.goblinDefeated then
		pushHud(player)
		return
	end

	if not state.chestOpened then
		pushHud(player)
		return
	end

	if state.exitBossDefeated then
		pushHud(player)
		return
	end

	if state.altarUsed then
		pushHud(player)
		return
	end

	local altarCost = config.AltarCost or 0
	if (state.coins or 0) < altarCost then
		pushHud(player)
		return
	end

	state.coins = (state.coins or 0) - altarCost
	state.bonusDamage = (state.bonusDamage or 0) + (config.AltarDamageBonus or 0)
	state.altarUsed = true
	state.altarBlessing = config.AltarBlessingName or "Bênção do Altar"
	pushHud(player)
end

local function fightGuardian(player)
	local state = getState(player)

	if not state.goblinDefeated then
		pushHud(player)
		return
	end

	if not state.chestOpened then
		pushHud(player)
		return
	end

	if state.exitBossDefeated then
		pushHud(player)
		return
	end

	local playerDamage = math.max(1, config.getTotalDamage(state))
	state.exitBossHp = math.max(0, (state.exitBossHp or config.ExitBossMaxHp) - playerDamage)

	if state.exitBossHp <= 0 then
		state.exitBossDefeated = true
	else
		local counterDamage = math.max(0, (config.ExitBossCounterDamage or 0) - config.getTotalDefense(state))
		if counterDamage > 0 then
			state.playerHp = math.max(1, (state.playerHp or state.playerMaxHp or config.PlayerMaxHp) - counterDamage)
		end
	end

	pushHud(player)
end

local function tryExit(player)
	local state = getState(player)

	if not state.goblinDefeated then
		pushHud(player)
		return
	end

	if not state.chestOpened then
		pushHud(player)
		return
	end

	if not state.exitBossDefeated then
		pushHud(player)
		return
	end

	state.runComplete = true
	pushHud(player)
end

for _, roomModel in ipairs(roomsFolder:GetChildren()) do
	if roomModel:IsA("Model") then
		connectRoomTrigger(roomModel)
	end
end

bindPrompt("GoblinRoom", config.Markers.Goblin, function(player)
	defeatGoblin(player)
end)

bindPrompt("TreasureRoom", config.Markers.Chest, function(player)
	openChest(player)
end)

bindPrompt("ExitRoom", config.Markers.Altar, function(player)
	useAltar(player)
end)

bindPrompt("ExitRoom", config.Markers.Guardian, function(player)
	fightGuardian(player)
end)

bindPrompt("ExitRoom", config.Markers.Exit, function(player)
	tryExit(player)
end)

Players.PlayerAdded:Connect(function(player)
	getState(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		pushHud(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
end)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local roomChangedEvent = remotesFolder:WaitForChild("RoomChanged")
local objectiveChangedEvent = remotesFolder:WaitForChild("ObjectiveChanged")

local config = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("DungeonConfig"))
local roomsFolder = workspace:WaitForChild(config.RoomsFolderName)
local rng = Random.new()
local runStore = DataStoreService:GetDataStore(config.RunSaveStoreName or "EchoesForgottenPrototypeRun")

local playerState = {}
local roomTriggers = {}
local persistenceAvailable = true
local getState
local pushHud

local STATE_SAVE_KEYS = {
	"currentRoom",
	"playerMaxHp",
	"playerHp",
	"coins",
	"bonusDamage",
	"bonusDefense",
	"goblinHp",
	"goblinDefeated",
	"exitBossHp",
	"exitBossDefeated",
	"guardianReward",
	"guardianRewardSummary",
	"chestOpened",
	"chestReward",
	"chestRewardSummary",
	"altarUsed",
	"altarBlessing",
	"runComplete",
	"playerDefeated",
	"defeatText",
}

local function warnPersistence(reason)
	if persistenceAvailable then
		warn("Save do prototipo indisponivel nesta sessao: " .. tostring(reason))
	end
	persistenceAvailable = false
end

local function getSaveKey(player)
	return string.format("run_%d", player.UserId)
end

local function createDefaultState()
	return {
		currentRoom = "StartRoom",
		hudRevision = 0,
		playerMaxHp = config.PlayerMaxHp,
		playerHp = config.PlayerStartHp or config.PlayerMaxHp,
		playerDefeated = false,
		defeatText = nil,
		coins = 0,
		bonusDamage = 0,
		bonusDefense = 0,
		goblinHp = config.GoblinMaxHp,
		goblinDefeated = false,
		exitBossHp = config.ExitBossMaxHp,
		exitBossDefeated = false,
		guardianReward = nil,
		guardianRewardSummary = nil,
		chestOpened = false,
		chestReward = nil,
		chestRewardSummary = nil,
		altarUsed = false,
		altarBlessing = nil,
		runComplete = false,
	}
end

local function serializeState(state)
	local snapshot = {}
	for _, key in ipairs(STATE_SAVE_KEYS) do
		local value = state[key]
		if value ~= nil then
			snapshot[key] = value
		end
	end
	return snapshot
end

local function hydrateState(state, snapshot)
	if type(snapshot) ~= "table" then
		return false
	end

	if snapshot.runComplete or snapshot.playerDefeated then
		return false
	end

	for _, key in ipairs(STATE_SAVE_KEYS) do
		local value = snapshot[key]
		if value ~= nil then
			state[key] = value
		end
	end

	return true
end

local function normalizeCombatState(state)
	if not state.goblinDefeated then
		state.goblinHp = config.GoblinMaxHp
	end

	if not state.exitBossDefeated then
		state.exitBossHp = config.ExitBossMaxHp
		state.guardianReward = nil
		state.guardianRewardSummary = nil
	end
end

local function clearSavedRun(player)
	if not persistenceAvailable then
		return
	end

	local ok, err = pcall(function()
		runStore:RemoveAsync(getSaveKey(player))
	end)

	if not ok then
		warnPersistence(err)
	end
end

local function saveRunState(player)
	if not persistenceAvailable then
		return
	end

	local state = playerState[player]
	if not state then
		return
	end

	if state.runComplete or state.playerDefeated then
		clearSavedRun(player)
		return
	end

	local snapshot = serializeState(state)
	local ok, err = pcall(function()
		runStore:SetAsync(getSaveKey(player), snapshot)
	end)

	if not ok then
		warnPersistence(err)
	end
end

local function loadSavedRun(player)
	if not persistenceAvailable then
		return nil
	end

	local ok, snapshot = pcall(function()
		return runStore:GetAsync(getSaveKey(player))
	end)

	if not ok then
		warnPersistence(snapshot)
		return nil
	end

	if type(snapshot) ~= "table" then
		return nil
	end

	if snapshot.runComplete or snapshot.playerDefeated then
		clearSavedRun(player)
		return nil
	end

	return snapshot
end

local function getRoomRestoreCFrame(roomName)
	local room = roomsFolder:FindFirstChild(roomName)
	if not room then
		return nil
	end

	local anchor = room.PrimaryPart
	if not anchor then
		anchor = room:FindFirstChild(config.TriggerName, true)
	end
	if not anchor or not anchor:IsA("BasePart") then
		anchor = room:FindFirstChildWhichIsA("BasePart", true)
	end
	if not anchor then
		return nil
	end

	return anchor.CFrame + Vector3.new(0, config.ResumeOffsetY or 4, 0)
end

local function restorePlayerToSavedRoom(player, character)
	local state = playerState[player]
	if not state or state.playerDefeated or state.runComplete then
		return false
	end

	local roomName = state.currentRoom
	if not roomName or roomName == "StartRoom" then
		return false
	end

	character = character or player.Character
	if not character then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local targetCFrame = getRoomRestoreCFrame(roomName)
	if not root or not targetCFrame then
		return false
	end

	for _ = 1, 5 do
		root.CFrame = targetCFrame
		task.wait(0.1)

		if (root.Position - targetCFrame.Position).Magnitude <= 6 then
			return true
		end
	end

	return false
end

local function isPositionInsidePart(part, worldPosition)
	local localPosition = part.CFrame:PointToObjectSpace(worldPosition)
	local halfSize = part.Size * 0.5
	local horizontalPadding = config.RoomTriggerHorizontalPadding or 2
	local verticalPadding = config.RoomTriggerVerticalPadding or 8

	return math.abs(localPosition.X) <= halfSize.X + horizontalPadding
		and math.abs(localPosition.Y) <= math.max(halfSize.Y, verticalPadding)
		and math.abs(localPosition.Z) <= halfSize.Z + horizontalPadding
end

local function configurePrompt(prompt)
	prompt.HoldDuration = config.PromptHoldDuration or 0
	prompt.MaxActivationDistance = config.PromptMaxActivationDistance or 10
	prompt.RequiresLineOfSight = config.PromptRequiresLineOfSight == true
	prompt.ClickablePrompt = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.UIOffset = config.PromptUIOffset or Vector2.new(0, 0)
end

local function commitState(player)
	local state = getState(player)
	state.hudRevision = (state.hudRevision or 0) + 1
	pushHud(player)
	saveRunState(player)
end

local function buildHudData(state)
	return {
		revision = state.hudRevision or 0,
		statsText = config.getStatsText(state),
		statsData = config.getStatsData(state),
		guardianData = {
			visible = state.currentRoom == "ExitRoom"
				and state.goblinDefeated
				and state.chestOpened
				and not state.exitBossDefeated
				and not state.playerDefeated,
			name = "Guardião Final",
			hp = state.exitBossHp or config.ExitBossMaxHp,
			maxHp = config.ExitBossMaxHp,
		},
		playerDefeated = state.playerDefeated,
		defeatText = state.defeatText,
		runComplete = state.runComplete,
		victoryText = config.getVictoryText(state),
	}
end

local function applyPlayerDamage(state, damageAmount, sourceName)
	if damageAmount <= 0 then
		return
	end

	state.playerHp = math.max(0, (state.playerHp or state.playerMaxHp or config.PlayerMaxHp) - damageAmount)
	if state.playerHp <= 0 then
		state.playerDefeated = true
		state.defeatText = string.format("Derrota. %s derrotou você. Reinicie a run.", sourceName)
	end
end

local function applyGuardianReward(state)
	local rewardEffect = config.GuardianRewardEffect
	local rewardAmount = config.GuardianRewardAmount or 0

	state.guardianReward = config.GuardianRewardName or "Premio do Guardiao"
	state.guardianRewardSummary = config.GuardianRewardSummary or ""

	if rewardEffect == "heal" then
		local maxHp = state.playerMaxHp or config.PlayerMaxHp
		state.playerHp = math.min(maxHp, (state.playerHp or maxHp) + rewardAmount)
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

getState = function(player)
	if not playerState[player] then
		playerState[player] = createDefaultState()
	end

	return playerState[player]
end

pushHud = function(player)
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
	if state.playerDefeated or state.runComplete then
		pushHud(player)
		return
	end

	if state.currentRoom == roomName then
		return
	end

	state.currentRoom = roomName
	commitState(player)
end

local function syncPlayerRoomFromCharacter(player)
	local state = playerState[player]
	if not state or state.playerDefeated or state.runComplete then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local bestRoomName = nil
	local bestDistance = nil

	for roomName, trigger in pairs(roomTriggers) do
		if trigger and trigger:IsDescendantOf(workspace) and isPositionInsidePart(trigger, root.Position) then
			local distance = (trigger.Position - root.Position).Magnitude
			if not bestDistance or distance < bestDistance then
				bestRoomName = roomName
				bestDistance = distance
			end
		end
	end

	if bestRoomName then
		setCurrentRoom(player, bestRoomName)
	end
end

local function startRoomSync(player, character)
	task.spawn(function()
		while player.Parent and character.Parent and player.Character == character do
			syncPlayerRoomFromCharacter(player)
			task.wait(0.15)
		end
	end)
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

	trigger.CanTouch = true
	roomTriggers[roomModel.Name] = trigger

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

	configurePrompt(prompt)

	prompt.Triggered:Connect(function(player)
		setCurrentRoom(player, roomName)
		callback(player, prompt)
	end)
end	

local function defeatGoblin(player)
	local state = getState(player)
	if state.playerDefeated or state.runComplete then
		pushHud(player)
		return
	end

	if state.goblinDefeated then
		pushHud(player)
		return
	end

	state.goblinHp = math.max(0, (state.goblinHp or config.GoblinMaxHp) - 1)
	if state.goblinHp <= 0 then
		state.goblinDefeated = true
		state.coins = (state.coins or 0) + (config.GoblinCoinReward or 0)
	else
		local counterDamage = math.max(0, (config.GoblinCounterDamage or 0) - config.getTotalDefense(state))
		applyPlayerDamage(state, counterDamage, "O Goblin")
	end
	commitState(player)
end

local function openChest(player)
	local state = getState(player)
	if state.playerDefeated or state.runComplete then
		pushHud(player)
		return
	end

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
	commitState(player)
end

local function useAltar(player)
	local state = getState(player)
	if state.playerDefeated or state.runComplete then
		pushHud(player)
		return
	end

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
	commitState(player)
end

local function fightGuardian(player)
	local state = getState(player)
	if state.playerDefeated or state.runComplete then
		pushHud(player)
		return
	end

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
		applyGuardianReward(state)
	else
		local counterDamage = math.max(0, (config.ExitBossCounterDamage or 0) - config.getTotalDefense(state))
		applyPlayerDamage(state, counterDamage, "O Guardião")
	end

	commitState(player)
end

local function tryExit(player)
	local state = getState(player)
	if state.playerDefeated then
		pushHud(player)
		return
	end

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
	commitState(player)
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
	local state = getState(player)
	local savedRun = loadSavedRun(player)
	if savedRun then
		hydrateState(state, savedRun)
	end
	normalizeCombatState(state)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.25)
		local restoredSavedRoom = restorePlayerToSavedRoom(player, character)
		if not restoredSavedRoom then
			syncPlayerRoomFromCharacter(player)
		end
		pushHud(player)
		startRoomSync(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	saveRunState(player)
	playerState[player] = nil
end)

game:BindToClose(function()
	for player, _ in pairs(playerState) do
		saveRunState(player)
	end
end)
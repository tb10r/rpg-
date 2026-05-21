local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local hud = script.Parent
local roomLabel = hud:WaitForChild("RoomLabel")
local objectiveLabel = hud:WaitForChild("ObjectiveLabel")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local roomChangedEvent = remotesFolder:WaitForChild("RoomChanged")
local objectiveChangedEvent = remotesFolder:WaitForChild("ObjectiveChanged")

local LEFT_MARGIN = 24
local TOP_MARGIN = 24
local SECTION_GAP = 12
local RESOURCE_WIDTH = 270
local RESOURCE_HEIGHT = 92
local MAX_LEFT_WIDTH = 520
local MIN_LEFT_WIDTH = 260
local ROOM_LABEL_HEIGHT = 34
local STATS_LABEL_HEIGHT = 42

local function createTextBlock(parent, name, position, size, font, textSize, textColor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = font
	label.Text = ""
	label.TextColor3 = textColor
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function createVictoryOverlay()
	local existingFrame = hud:FindFirstChild("VictoryFrame")
	if existingFrame then
		return existingFrame, existingFrame:FindFirstChild("TitleLabel"), existingFrame:FindFirstChild("BodyLabel")
	end

	local frame = Instance.new("Frame")
	frame.Name = "VictoryFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 460, 0, 240)
	frame.BackgroundColor3 = Color3.fromRGB(18, 24, 31)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = hud

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(207, 170, 73)
	stroke.Thickness = 2
	stroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 24, 0, 18)
	titleLabel.Size = UDim2.new(1, -48, 0, 36)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "Vitória"
	titleLabel.TextColor3 = Color3.fromRGB(248, 233, 194)
	titleLabel.TextSize = 28
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = frame

	local bodyLabel = Instance.new("TextLabel")
	bodyLabel.Name = "BodyLabel"
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.Position = UDim2.new(0, 24, 0, 68)
	bodyLabel.Size = UDim2.new(1, -48, 1, -92)
	bodyLabel.Font = Enum.Font.Gotham
	bodyLabel.Text = ""
	bodyLabel.TextColor3 = Color3.fromRGB(232, 232, 228)
	bodyLabel.TextSize = 20
	bodyLabel.TextWrapped = true
	bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	bodyLabel.Parent = frame

	return frame, titleLabel, bodyLabel
end

local function createStatsLabel()
	local existingLabel = hud:FindFirstChild("StatsLabel")
	if existingLabel then
		return existingLabel
	end

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.AnchorPoint = objectiveLabel.AnchorPoint
	statsLabel.Position = objectiveLabel.Position + UDim2.new(0, 0, 0, 56)
	statsLabel.Size = UDim2.new(0, 430, 0, 42)
	statsLabel.BackgroundColor3 = Color3.fromRGB(18, 24, 31)
	statsLabel.BackgroundTransparency = 0.15
	statsLabel.BorderSizePixel = 0
	statsLabel.Font = Enum.Font.GothamSemibold
	statsLabel.Text = "Dano: 1 | Defesa: 0"
	statsLabel.TextColor3 = Color3.fromRGB(248, 233, 194)
	statsLabel.TextSize = 17
	statsLabel.TextWrapped = true
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = hud

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = statsLabel

	return statsLabel
end

local function createResourcesFrame()
	local existingFrame = hud:FindFirstChild("ResourcesFrame")
	if existingFrame then
		return existingFrame, existingFrame:FindFirstChild("HpLabel"), existingFrame:FindFirstChild("CoinsLabel")
	end

	local frame = Instance.new("Frame")
	frame.Name = "ResourcesFrame"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -24, 0, 24)
	frame.Size = UDim2.new(0, RESOURCE_WIDTH, 0, RESOURCE_HEIGHT)
	frame.BackgroundColor3 = Color3.fromRGB(18, 24, 31)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Parent = hud

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(86, 103, 122)
	stroke.Thickness = 1.5
	stroke.Parent = frame

	local titleLabel = createTextBlock(
		frame,
		"ResourcesTitle",
		UDim2.new(0, 16, 0, 10),
		UDim2.new(1, -32, 0, 22),
		Enum.Font.GothamBold,
		15,
		Color3.fromRGB(248, 233, 194)
	)
	titleLabel.Text = "Status do aventureiro"

	local hpLabel = createTextBlock(
		frame,
		"HpLabel",
		UDim2.new(0, 16, 0, 38),
		UDim2.new(1, -32, 0, 20),
		Enum.Font.GothamSemibold,
		18,
		Color3.fromRGB(239, 117, 117)
	)
	hpLabel.Text = "HP: 100/100"

	local coinsLabel = createTextBlock(
		frame,
		"CoinsLabel",
		UDim2.new(0, 16, 0, 62),
		UDim2.new(1, -32, 0, 20),
		Enum.Font.GothamSemibold,
		18,
		Color3.fromRGB(232, 196, 92)
	)
	coinsLabel.Text = "Moedas: 0"

	return frame, hpLabel, coinsLabel
end

local victoryFrame, _, victoryBodyLabel = createVictoryOverlay()
local statsLabel = createStatsLabel()
local resourcesFrame, hpLabel, coinsLabel = createResourcesFrame()

local function getObjectiveHeight(width)
	local textBounds = TextService:GetTextSize(
		objectiveLabel.Text or "",
		objectiveLabel.TextSize,
		objectiveLabel.Font,
		Vector2.new(width, 1000)
	)

	return math.max(48, textBounds.Y + 14)
end

local function refreshHudLayout()
	local hudWidth = hud.AbsoluteSize.X
	local leftWidth = math.clamp(hudWidth - RESOURCE_WIDTH - (LEFT_MARGIN * 3), MIN_LEFT_WIDTH, MAX_LEFT_WIDTH)
	local roomY = TOP_MARGIN
	local objectiveY = roomY + ROOM_LABEL_HEIGHT + 6
	local objectiveHeight = getObjectiveHeight(leftWidth)
	local statsY = objectiveY + objectiveHeight + SECTION_GAP
	local resourcesX = math.max(LEFT_MARGIN, hudWidth - LEFT_MARGIN - RESOURCE_WIDTH)
	local resourcesY = TOP_MARGIN
	local leftBlockRight = LEFT_MARGIN + leftWidth

	roomLabel.AnchorPoint = Vector2.new(0, 0)
	roomLabel.Position = UDim2.fromOffset(LEFT_MARGIN, roomY)
	roomLabel.Size = UDim2.fromOffset(leftWidth, ROOM_LABEL_HEIGHT)
	roomLabel.TextXAlignment = Enum.TextXAlignment.Left

	objectiveLabel.AnchorPoint = Vector2.new(0, 0)
	objectiveLabel.Position = UDim2.fromOffset(LEFT_MARGIN, objectiveY)
	objectiveLabel.Size = UDim2.fromOffset(leftWidth, objectiveHeight)
	objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left

	statsLabel.AnchorPoint = Vector2.new(0, 0)
	statsLabel.Position = UDim2.fromOffset(LEFT_MARGIN, statsY)
	statsLabel.Size = UDim2.fromOffset(leftWidth, STATS_LABEL_HEIGHT)

	if resourcesX < leftBlockRight + SECTION_GAP then
		resourcesY = statsY + STATS_LABEL_HEIGHT + SECTION_GAP
	end

	resourcesFrame.Position = UDim2.fromOffset(resourcesX + RESOURCE_WIDTH, resourcesY)
end

local function parseStatsText(statsText)
	if not statsText or statsText == "" then
		return nil
	end

	local hp, maxHp, coins, damage, defense = string.match(
		statsText,
		"HP:%s*(%d+)%/(%d+)%s*|%s*Moedas:%s*(%d+)%s*|%s*Dano:%s*(%d+)%s*|%s*Defesa:%s*(%d+)"
	)

	if not hp then
		return nil
	end

	return {
		hp = tonumber(hp),
		maxHp = tonumber(maxHp),
		coins = tonumber(coins),
		damage = tonumber(damage),
		defense = tonumber(defense),
	}
end

local function applyHudData(hudData)
	if not hudData then
		return
	end

	local statsData = hudData.statsData or parseStatsText(hudData.statsText)
	if statsData then
		hpLabel.Text = string.format("HP: %d/%d", statsData.hp or 0, statsData.maxHp or 0)
		coinsLabel.Text = string.format("Moedas: %d", statsData.coins or 0)
		statsLabel.Text = string.format("Dano: %d | Defesa: %d", statsData.damage or 0, statsData.defense or 0)
	elseif hudData.statsText then
		statsLabel.Text = hudData.statsText
	end

	if hudData.runComplete then
		victoryBodyLabel.Text = hudData.victoryText or "Você escapou da dungeon."
		victoryFrame.Visible = true
	else
		victoryFrame.Visible = false
	end

	refreshHudLayout()
end

roomLabel.Text = "Sala Inicial"
objectiveLabel.Text = "Explore a dungeon."
objectiveLabel.TextWrapped = true
objectiveLabel.TextYAlignment = Enum.TextYAlignment.Top
roomLabel.TextYAlignment = Enum.TextYAlignment.Center
statsLabel.TextYAlignment = Enum.TextYAlignment.Center

refreshHudLayout()

hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshHudLayout)


roomChangedEvent.OnClientEvent:Connect(function(roomName, objectiveText, hudData)
	roomLabel.Text = roomName
	if objectiveText then
		objectiveLabel.Text = objectiveText
	end
	applyHudData(hudData)
	refreshHudLayout()
end)

objectiveChangedEvent.OnClientEvent:Connect(function(objectiveText, hudData)
	objectiveLabel.Text = objectiveText
	applyHudData(hudData)
	refreshHudLayout()
end)
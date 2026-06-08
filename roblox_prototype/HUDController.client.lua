local GuiService = game:GetService("GuiService")
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

local function ensureCorner(guiObject, name, radius)
	local corner = guiObject:FindFirstChild(name)
	if not corner then
		corner = Instance.new("UICorner")
		corner.Name = name
		corner.Parent = guiObject
	end

	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function ensureStroke(guiObject, name, color, transparency, thickness)
	local stroke = guiObject:FindFirstChild(name)
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = name
		stroke.Parent = guiObject
	end

	stroke.Color = color
	stroke.Transparency = transparency or 0
	stroke.Thickness = thickness or 1
	return stroke
end

local function ensureGradient(guiObject, name, colorSequence, rotation)
	local gradient = guiObject:FindFirstChild(name)
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = name
		gradient.Parent = guiObject
	end

	gradient.Color = colorSequence
	gradient.Rotation = rotation or 90
	return gradient
end

local function ensurePadding(guiObject, name, left, right, top, bottom)
	local padding = guiObject:FindFirstChild(name)
	if not padding then
		padding = Instance.new("UIPadding")
		padding.Name = name
		padding.Parent = guiObject
	end

	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right)
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingBottom = UDim.new(0, bottom)
	return padding
end

local function styleDisplayLabel(label, font, textSize, textColor, backgroundColor, backgroundTransparency)
	label.Font = font
	label.TextSize = textSize
	label.TextColor3 = textColor
	label.BackgroundColor3 = backgroundColor
	label.BackgroundTransparency = backgroundTransparency
	label.BorderSizePixel = 0

	ensureCorner(label, "AutoCorner", 12)
	ensureStroke(label, "AutoStroke", Color3.fromRGB(92, 111, 130), 0.35, 1.25)
	ensurePadding(label, "AutoPadding", 12, 12, 0, 0)
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

	ensureGradient(
		frame,
		"OverlayGradient",
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 45, 57)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 21, 28)),
		}),
		90
	)

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

local function createGuardianFrame()
	local existingFrame = hud:FindFirstChild("GuardianFrame")
	if existingFrame then
		return existingFrame, existingFrame:FindFirstChild("GuardianNameLabel"), existingFrame:FindFirstChild("GuardianHpLabel"), existingFrame:FindFirstChild("GuardianBarBackground"), existingFrame:FindFirstChild("GuardianBarBackground"):FindFirstChild("GuardianBarFill")
	end

	local frame = Instance.new("Frame")
	frame.Name = "GuardianFrame"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -24)
	frame.Size = UDim2.new(0, 430, 0, 88)
	frame.BackgroundColor3 = Color3.fromRGB(18, 24, 31)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = hud

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(150, 76, 76)
	stroke.Thickness = 1.5
	stroke.Parent = frame

	ensureGradient(
		frame,
		"GuardianGradient",
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(37, 25, 29)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 24, 31)),
		}),
		0
	)

	local nameLabel = createTextBlock(
		frame,
		"GuardianNameLabel",
		UDim2.new(0, 16, 0, 10),
		UDim2.new(1, -32, 0, 24),
		Enum.Font.GothamBold,
		16,
		Color3.fromRGB(248, 233, 194)
	)
	nameLabel.Text = "Guardião Final"

	local hpLabel = createTextBlock(
		frame,
		"GuardianHpLabel",
		UDim2.new(0, 16, 0, 56),
		UDim2.new(1, -32, 0, 18),
		Enum.Font.GothamSemibold,
		15,
		Color3.fromRGB(232, 232, 228)
	)
	hpLabel.Text = "HP: 5/5"

	local barBackground = Instance.new("Frame")
	barBackground.Name = "GuardianBarBackground"
	barBackground.Position = UDim2.new(0, 16, 0, 38)
	barBackground.Size = UDim2.new(1, -32, 0, 12)
	barBackground.BackgroundColor3 = Color3.fromRGB(62, 70, 78)
	barBackground.BorderSizePixel = 0
	barBackground.Parent = frame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 999)
	barCorner.Parent = barBackground

	local barFill = Instance.new("Frame")
	barFill.Name = "GuardianBarFill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(207, 82, 82)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBackground

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 999)
	fillCorner.Parent = barFill

	return frame, nameLabel, hpLabel, barBackground, barFill
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

	ensureStroke(statsLabel, "StatsStroke", Color3.fromRGB(92, 111, 130), 0.35, 1.25)
	ensurePadding(statsLabel, "StatsPadding", 12, 12, 0, 0)

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

	ensureGradient(
		frame,
		"ResourcesGradient",
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 42, 53)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 24, 31)),
		}),
		90
	)

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

local resultFrame, resultTitleLabel, resultBodyLabel = createVictoryOverlay()
local statsLabel = createStatsLabel()
local resourcesFrame, hpLabel, coinsLabel = createResourcesFrame()
local guardianFrame, guardianNameLabel, guardianHpLabel, _, guardianBarFill = createGuardianFrame()
local lastHudRevision = -1
local hudState = {
	roomName = "Sala Inicial",
	objectiveText = "Explore a dungeon.",
	hudData = nil,
}

styleDisplayLabel(
	roomLabel,
	Enum.Font.GothamBold,
	18,
	Color3.fromRGB(248, 233, 194),
	Color3.fromRGB(18, 24, 31),
	0.12
)
roomLabel.TextWrapped = false
roomLabel.TextTruncate = Enum.TextTruncate.None
roomLabel.RichText = false

styleDisplayLabel(
	objectiveLabel,
	Enum.Font.Gotham,
	16,
	Color3.fromRGB(232, 232, 228),
	Color3.fromRGB(18, 24, 31),
	0.08
)
objectiveLabel.TextWrapped = true
objectiveLabel.TextTruncate = Enum.TextTruncate.None
objectiveLabel.RichText = false

local function getSafeInset()
	local topLeftInset = GuiService:GetGuiInset()
	return topLeftInset.X, topLeftInset.Y
end

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
	local insetX, insetY = getSafeInset()
	local leftMargin = LEFT_MARGIN + insetX
	local topMargin = TOP_MARGIN + insetY
	local leftWidth = math.clamp(hudWidth - RESOURCE_WIDTH - insetX - (LEFT_MARGIN * 3), MIN_LEFT_WIDTH, MAX_LEFT_WIDTH)
	local roomY = topMargin
	local objectiveY = roomY + ROOM_LABEL_HEIGHT + 6
	local objectiveHeight = getObjectiveHeight(leftWidth)
	local statsY = objectiveY + objectiveHeight + SECTION_GAP
	local resourcesX = math.max(leftMargin, hudWidth - LEFT_MARGIN - RESOURCE_WIDTH)
	local resourcesY = topMargin
	local leftBlockRight = leftMargin + leftWidth

	roomLabel.AnchorPoint = Vector2.new(0, 0)
	roomLabel.Position = UDim2.fromOffset(leftMargin, roomY)
	roomLabel.Size = UDim2.fromOffset(leftWidth, ROOM_LABEL_HEIGHT)
	roomLabel.TextXAlignment = Enum.TextXAlignment.Left

	objectiveLabel.AnchorPoint = Vector2.new(0, 0)
	objectiveLabel.Position = UDim2.fromOffset(leftMargin, objectiveY)
	objectiveLabel.Size = UDim2.fromOffset(leftWidth, objectiveHeight)
	objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left

	statsLabel.AnchorPoint = Vector2.new(0, 0)
	statsLabel.Position = UDim2.fromOffset(leftMargin, statsY)
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

local function parseGuardianDataFromObjective(objectiveText)
	if not objectiveText or objectiveText == "" then
		return nil
	end

	local hp, maxHp = string.match(objectiveText, "HP do Guardi[^:]*:%s*(%d+)%/(%d+)")
	if not hp or not maxHp then
		return nil
	end

	return {
		visible = true,
		name = "Guardião Final",
		hp = tonumber(hp),
		maxHp = tonumber(maxHp),
	}
end

local function resolveGuardianData(hudData, objectiveText)
	local guardianData = hudData and hudData.guardianData or nil
	local parsedGuardianData = parseGuardianDataFromObjective(objectiveText)

	if parsedGuardianData then
		guardianData = {
			visible = true,
			name = (guardianData and guardianData.name) or parsedGuardianData.name,
			hp = parsedGuardianData.hp,
			maxHp = parsedGuardianData.maxHp,
		}
	elseif guardianData then
		guardianData = {
			visible = guardianData.visible == true,
			name = guardianData.name or "Guardião Final",
			hp = guardianData.hp,
			maxHp = guardianData.maxHp,
		}
	end

	return guardianData
end

local function applyHudData(hudData, objectiveText)
	if not hudData then
		hudData = {}
	end

	local statsData = hudData.statsData or parseStatsText(hudData.statsText)
	if statsData then
		local maxHp = math.max(1, statsData.maxHp or 1)
		local hpRatio = math.clamp((statsData.hp or maxHp) / maxHp, 0, 1)

		hpLabel.Text = string.format("HP: %d/%d", statsData.hp or 0, statsData.maxHp or 0)
		coinsLabel.Text = string.format("Moedas: %d", statsData.coins or 0)
		statsLabel.Text = string.format("Dano: %d | Defesa: %d", statsData.damage or 0, statsData.defense or 0)

		if hpRatio > 0.65 then
			hpLabel.TextColor3 = Color3.fromRGB(122, 232, 153)
		elseif hpRatio > 0.3 then
			hpLabel.TextColor3 = Color3.fromRGB(242, 196, 95)
		else
			hpLabel.TextColor3 = Color3.fromRGB(239, 117, 117)
		end
	elseif hudData.statsText then
		statsLabel.Text = hudData.statsText
	end

	local guardianData = resolveGuardianData(hudData, objectiveText)
	if guardianData and guardianData.visible then
		local maxHp = math.max(1, guardianData.maxHp or 1)
		local currentHp = math.clamp(guardianData.hp or maxHp, 0, maxHp)
		local hpRatio = currentHp / maxHp

		guardianNameLabel.Text = guardianData.name or "Guardião Final"
		guardianHpLabel.Text = string.format("HP: %d/%d", currentHp, maxHp)
		guardianBarFill.Size = UDim2.new(hpRatio, 0, 1, 0)

		if hpRatio > 0.65 then
			guardianBarFill.BackgroundColor3 = Color3.fromRGB(204, 111, 111)
		elseif hpRatio > 0.3 then
			guardianBarFill.BackgroundColor3 = Color3.fromRGB(196, 82, 82)
		else
			guardianBarFill.BackgroundColor3 = Color3.fromRGB(148, 43, 43)
		end

		guardianFrame.Visible = true
	else
		guardianFrame.Visible = false
	end

	if hudData.runComplete then
		resultTitleLabel.Text = "Vitória"
		resultTitleLabel.TextColor3 = Color3.fromRGB(248, 233, 194)
		resultBodyLabel.Text = hudData.victoryText or "Você escapou da dungeon."
		resultFrame.Visible = true
	elseif hudData.playerDefeated then
		resultTitleLabel.Text = "Derrota"
		resultTitleLabel.TextColor3 = Color3.fromRGB(239, 117, 117)
		resultBodyLabel.Text = hudData.defeatText or "O aventureiro caiu na dungeon."
		resultFrame.Visible = true
		guardianFrame.Visible = false
	else
		resultFrame.Visible = false
	end

	refreshHudLayout()
end

local function shouldApplyHudPayload(hudData)
	if not hudData then
		return true
	end

	local revision = hudData.revision
	if revision == nil then
		return true
	end

	if revision < lastHudRevision then
		return false
	end

	lastHudRevision = revision
	return true
end

local function renderHud()
	roomLabel.Text = hudState.roomName or "Sala Inicial"
	objectiveLabel.Text = hudState.objectiveText or "Explore a dungeon."
	applyHudData(hudState.hudData, hudState.objectiveText)
	refreshHudLayout()
end

roomLabel.Text = hudState.roomName
objectiveLabel.Text = hudState.objectiveText
objectiveLabel.TextWrapped = true
objectiveLabel.TextYAlignment = Enum.TextYAlignment.Top
roomLabel.TextYAlignment = Enum.TextYAlignment.Center
statsLabel.TextYAlignment = Enum.TextYAlignment.Center

renderHud()

hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshHudLayout)


roomChangedEvent.OnClientEvent:Connect(function(roomName, objectiveText, hudData)
	if not shouldApplyHudPayload(hudData) then
		return
	end

	if roomName and roomName ~= "" then
		hudState.roomName = roomName
	end
	if objectiveText and objectiveText ~= "" then
		hudState.objectiveText = objectiveText
	end
	if hudData then
		hudState.hudData = hudData
	end
	renderHud()
end)

objectiveChangedEvent.OnClientEvent:Connect(function(objectiveText, hudData)
	if not shouldApplyHudPayload(hudData) then
		return
	end

	if objectiveText and objectiveText ~= "" then
		hudState.objectiveText = objectiveText
	end
	if hudData then
		hudState.hudData = hudData
	end
	renderHud()
end)
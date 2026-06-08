local DungeonConfig = {}

DungeonConfig.PlayerMaxHp = 100
DungeonConfig.PlayerStartHp = 100
DungeonConfig.PlayerBaseDamage = 1
DungeonConfig.PlayerBaseDefense = 0
DungeonConfig.GoblinMaxHp = 3
DungeonConfig.GoblinCounterDamage = 10
DungeonConfig.GoblinCoinReward = 20
DungeonConfig.ExitBossMaxHp = 5
DungeonConfig.ExitBossCounterDamage = 14
DungeonConfig.GuardianRewardName = "Insignia do Guardiao"
DungeonConfig.GuardianRewardEffect = "defense"
DungeonConfig.GuardianRewardAmount = 2
DungeonConfig.GuardianRewardSummary = "+2 defesa"
DungeonConfig.AltarCost = 20
DungeonConfig.AltarDamageBonus = 1
DungeonConfig.AltarBlessingName = "Força Ancestral"
DungeonConfig.RunSaveStoreName = "EchoesForgottenPrototypeRun"
DungeonConfig.ResumeOffsetY = 4
DungeonConfig.PromptHoldDuration = 0
DungeonConfig.PromptMaxActivationDistance = 12
DungeonConfig.PromptRequiresLineOfSight = false
DungeonConfig.PromptUIOffset = Vector2.new(0, 18)
DungeonConfig.ChestRewards = {
	{
		name = "Poção de Cura",
		effect = "heal",
		amount = 25,
		summary = "+25 HP",
	},
	{
		name = "Punhado de Moedas",
		effect = "coins",
		amount = 30,
		summary = "+30 moedas",
	},
	{
		name = "Pedra de Afiar",
		effect = "damage",
		amount = 1,
		summary = "+1 dano",
	},
	{
		name = "Escudo Antigo",
		effect = "defense",
		amount = 1,
		summary = "+1 defesa",
	},
}

DungeonConfig.RoomDisplayNames = {
	StartRoom = "Sala Inicial",
	GoblinRoom = "Sala do Goblin",
	TreasureRoom = "Sala do Tesouro",
	CorridorRoom = "Corredor",
	ExitRoom = "Saída",
}

DungeonConfig.DefaultObjectives = {
	StartRoom = "Explore a dungeon.",
	GoblinRoom = "Derrote o Goblin.",
	TreasureRoom = "Abra o baú.",
	CorridorRoom = "Atravesse o corredor.",
	ExitRoom = "Encontre uma forma de escapar.",
}

DungeonConfig.RoomsFolderName = "Rooms"
DungeonConfig.TriggerName = "RoomTrigger"

DungeonConfig.Markers = {
	Goblin = "GoblinMarker",
	Chest = "ChestMarker",
	Guardian = "GuardianMarker",
	Altar = "AltarMarker",
	Exit = "ExitMarker",
}

local function getRewardText(state)
	local rewardName = state.chestReward or "um tesouro misterioso"
	local rewardSummary = state.chestRewardSummary
	if rewardSummary and rewardSummary ~= "" then
		return string.format("%s (%s)", rewardName, rewardSummary)
	end
	return rewardName
end

local function getGuardianRewardText(state)
	local rewardName = state.guardianReward or DungeonConfig.GuardianRewardName
	local rewardSummary = state.guardianRewardSummary or DungeonConfig.GuardianRewardSummary
	if rewardSummary and rewardSummary ~= "" then
		return string.format("%s (%s)", rewardName, rewardSummary)
	end
	return rewardName
end

function DungeonConfig.getTotalDamage(state)
	state = state or {}
	return DungeonConfig.PlayerBaseDamage + (state.bonusDamage or 0)
end

function DungeonConfig.getTotalDefense(state)
	state = state or {}
	return DungeonConfig.PlayerBaseDefense + (state.bonusDefense or 0)
end

function DungeonConfig.getStatsText(state)
	state = state or {}

	local currentHp = state.playerHp or DungeonConfig.PlayerStartHp
	local maxHp = state.playerMaxHp or DungeonConfig.PlayerMaxHp
	local coins = state.coins or 0
	local damage = DungeonConfig.getTotalDamage(state)
	local defense = DungeonConfig.getTotalDefense(state)

	return string.format("HP: %d/%d | Moedas: %d | Dano: %d | Defesa: %d", currentHp, maxHp, coins, damage, defense)
end

function DungeonConfig.getStatsData(state)
	state = state or {}

	local currentHp = state.playerHp or DungeonConfig.PlayerStartHp
	local maxHp = state.playerMaxHp or DungeonConfig.PlayerMaxHp
	local coins = state.coins or 0
	local damage = DungeonConfig.getTotalDamage(state)
	local defense = DungeonConfig.getTotalDefense(state)

	return {
		hp = currentHp,
		maxHp = maxHp,
		coins = coins,
		damage = damage,
		defense = defense,
	}
end

function DungeonConfig.getVictoryText(state)
	state = state or {}
	local altarLine = ""
	local guardianLine = ""
	if state.altarUsed then
		altarLine = string.format("\nBênção do altar: %s (+%d dano)", DungeonConfig.AltarBlessingName, DungeonConfig.AltarDamageBonus)
	end
	if state.exitBossDefeated then
		guardianLine = string.format("\nRecompensa do Guardião: %s", getGuardianRewardText(state))
	end

	return string.format(
		"Você escapou da dungeon.\nRecompensa do baú: %s%s%s\n%s",
		getRewardText(state),
		guardianLine,
		altarLine,
		DungeonConfig.getStatsText(state)
	)
end

function DungeonConfig.getObjective(roomName, state)
	state = state or {}

	if state.playerDefeated then
		return state.defeatText or "Derrota. O aventureiro caiu na dungeon."
	end

	if roomName == "StartRoom" then
		return "Explore a dungeon."
	end

	if roomName == "GoblinRoom" then
		if state.goblinDefeated then
			return string.format(
				"Goblin derrotado. Você ganhou %d moedas. Vá até a sala do tesouro.",
				DungeonConfig.GoblinCoinReward
			)
		end
		local currentHp = state.goblinHp or DungeonConfig.GoblinMaxHp
		return string.format("Derrote o Goblin. HP restante: %d/%d.", currentHp, DungeonConfig.GoblinMaxHp)
	end

	if roomName == "TreasureRoom" then
		if not state.goblinDefeated then
			return "Antes do baú, você precisa derrotar o Goblin."
		end
		if state.chestOpened then
			if not state.altarUsed and (state.coins or 0) >= DungeonConfig.AltarCost then
				return string.format(
					"Baú aberto. Você recebeu: %s. Siga pelo corredor até a saída, use o altar se quiser comprar %s por %d moedas e prepare-se para o Guardião.",
					getRewardText(state),
					DungeonConfig.AltarBlessingName,
					DungeonConfig.AltarCost
				)
			end
			return string.format("Baú aberto. Você recebeu: %s. Siga pelo corredor até a saída e enfrente o Guardião.", getRewardText(state))
		end
		return "Abra o baú."
	end

	if roomName == "CorridorRoom" then
		if not state.goblinDefeated then
			return "O corredor leva adiante, mas você ainda precisa derrotar o Goblin."
		end

		if not state.chestOpened then
			return "Antes de seguir, abra o baú na sala do tesouro."
		end

		if state.exitBossDefeated then
			return "O corredor está livre. Vá até a saída e escape da dungeon."
		end

		if not state.altarUsed and (state.coins or 0) >= DungeonConfig.AltarCost then
			return string.format(
				"Atravesse o corredor. Na próxima sala, você pode usar o altar para comprar %s por %d moedas antes do Guardião.",
				DungeonConfig.AltarBlessingName,
				DungeonConfig.AltarCost
			)
		end

		return "Atravesse o corredor e prepare-se para enfrentar o Guardião na saída."
	end

	if roomName == "ExitRoom" then
		if state.runComplete then
			return "Vitória! A tela final já apareceu."
		end
		if state.goblinDefeated and state.chestOpened then
			local currentCoins = state.coins or 0
			local bossHp = state.exitBossHp or DungeonConfig.ExitBossMaxHp
			local totalDamage = DungeonConfig.getTotalDamage(state)
			local totalDefense = DungeonConfig.getTotalDefense(state)

			if not state.exitBossDefeated then
				if not state.altarUsed and currentCoins >= DungeonConfig.AltarCost then
					return string.format(
						"O Guardião bloqueia a saída. Use o altar para comprar %s ou ataque agora. HP do Guardião: %d/%d. Seu dano: %d. Sua defesa: %d.",
						DungeonConfig.AltarBlessingName,
						bossHp,
						DungeonConfig.ExitBossMaxHp,
						totalDamage,
						totalDefense
					)
				end

				return string.format(
					"O Guardião bloqueia a saída. Ataque-o para abrir o caminho. HP do Guardião: %d/%d. Seu dano: %d. Sua defesa: %d.",
					bossHp,
					DungeonConfig.ExitBossMaxHp,
					totalDamage,
					totalDefense
				)
			end

			if state.altarUsed then
				return string.format(
					"Guardião derrotado. Você recebeu %s e a bênção %s já foi comprada. Use o prompt para escapar.",
					getGuardianRewardText(state),
					DungeonConfig.AltarBlessingName,
					getRewardText(state)
				)
			end

			return string.format(
				"Guardião derrotado. Você recebeu %s. Leve %s com você e use o prompt para escapar.",
				getGuardianRewardText(state),
				getRewardText(state)
			)
		end
		return "Ainda não é hora de sair."
	end

	return "Continue explorando."
end

return DungeonConfig
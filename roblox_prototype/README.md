# Roblox Prototype - Day 2

Arquivos de referência para montar o primeiro loop jogável de Echoes of the Forgotten no Roblox Studio.

Objetivo deste pacote:

- mostrar o nome da sala na HUD
- mostrar o objetivo atual na HUD
- mostrar os status da run na HUD
- permitir derrotar o Goblin via ProximityPrompt
- permitir abrir o baú via ProximityPrompt e receber uma recompensa com efeito real
- permitir gastar moedas em um altar antes de sair
- permitir enfrentar um guardião final usando dano e defesa da run
- permitir sair da dungeon quando as condições forem cumpridas
- mostrar uma tela simples de vitória no fim da run

## Estrutura esperada no Roblox Studio

Workspace

- Rooms
  - StartRoom
    - RoomTrigger
  - GoblinRoom
    - RoomTrigger
    - GoblinMarker
      - ProximityPrompt
  - TreasureRoom
    - RoomTrigger
    - ChestMarker
      - ProximityPrompt
  - ExitRoom
    - RoomTrigger
    - GuardianMarker
      - ProximityPrompt
    - AltarMarker
      - ProximityPrompt
    - ExitMarker
      - ProximityPrompt

ReplicatedStorage

- Remotes
  - RoomChanged
  - ObjectiveChanged
- Configs
  - DungeonConfig (ModuleScript)

ServerScriptService

- Services
  - DungeonService (Script)

StarterGui

- HUD
  - RoomLabel
  - ObjectiveLabel
  - HUDController (LocalScript)

Observação:

- StatsLabel e VictoryFrame são criados automaticamente pelo HUDController. Você não precisa montar esses dois objetos manualmente.

## Nomes importantes

Os nomes abaixo precisam bater exatamente:

- StartRoom
- GoblinRoom
- TreasureRoom
- ExitRoom
- RoomTrigger
- GoblinMarker
- ChestMarker
- ExitMarker
- GuardianMarker
- AltarMarker
- RoomChanged
- ObjectiveChanged
- DungeonConfig
- DungeonService
- HUDController

## Configuração dos triggers

Para cada RoomTrigger:

- Anchored = true
- CanCollide = false
- Transparency = 1
- CanTouch = true

## Configuração dos prompts

Dentro de cada marcador, adicione um ProximityPrompt.

Sugestão de texto:

- GoblinMarker > ProximityPrompt
  - ActionText = "Atacar"
  - ObjectText = "Goblin"

- ChestMarker > ProximityPrompt
  - ActionText = "Abrir"
  - ObjectText = "Baú"

- AltarMarker > ProximityPrompt
  - ActionText = "Oferecer Moedas"
  - ObjectText = "Altar"

- GuardianMarker > ProximityPrompt
  - ActionText = "Atacar"
  - ObjectText = "Guardião"

- ExitMarker > ProximityPrompt
  - ActionText = "Sair"
  - ObjectText = "Saída"

## Onde colar cada arquivo

- roblox_prototype/DungeonConfig.lua -> ReplicatedStorage/Configs/DungeonConfig
- roblox_prototype/DungeonService.server.lua -> ServerScriptService/Services/DungeonService
- roblox_prototype/HUDController.client.lua -> StarterGui/HUD/HUDController

## Fluxo esperado ao testar

1. Jogador entra e vê a Sala Inicial.
2. Jogador entra em GoblinRoom, vê o HP do Goblin e os status da run na HUD.
3. Ao usar o prompt do Goblin, o Goblin perde HP, o jogador leva contra-ataque até vencer e ganha 20 moedas ao derrotá-lo.
4. Ao abrir o baú, uma recompensa é sorteada e aplicada na run.
5. Se o jogador tiver moedas suficientes, ele pode usar o altar na saída para comprar +1 dano por 20 moedas.
6. O Guardião final bloqueia a saída; o dano da run reduz o HP dele e a defesa reduz o contra-ataque.
7. Ao derrotar o Guardião e usar a saída, aparece um painel de vitória com a recompensa e os status finais.
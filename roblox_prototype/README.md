# Roblox Prototype - Day 2

Arquivos de referência para montar o primeiro loop jogável de Echoes of the Forgotten no Roblox Studio.

Objetivo deste pacote:

- mostrar o nome da sala na HUD
- mostrar o objetivo atual na HUD
- mostrar os status da run na HUD
- salvar e restaurar a run ativa de forma simples
- permitir derrotar o Goblin via ProximityPrompt
- permitir abrir o baú via ProximityPrompt e receber uma recompensa com efeito real
- permitir gastar moedas em um altar antes de sair
- permitir enfrentar um guardião final usando dano e defesa da run
- encerrar a run em derrota quando o HP do jogador chegar a 0
- mostrar uma barra visual de HP do Guardião na HUD
- dar uma recompensa específica ao derrotar o Guardião
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
  - CorridorRoom
    - RoomTrigger
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

- StatsLabel, VictoryFrame e GuardianFrame são criados automaticamente pelo HUDController. Você não precisa montar esses objetos manualmente.
- DungeonService aplica estilo base nos ProximityPrompts automaticamente. Você só precisa configurar ActionText e ObjectText.
- Para o save simples funcionar no Roblox Studio, publique o place e ative Game Settings > Security > Enable Studio Access to API Services.

## Nomes importantes

Os nomes abaixo precisam bater exatamente:

- StartRoom
- GoblinRoom
- TreasureRoom
- CorridorRoom
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
5. Jogador atravessa o CorridorRoom antes de chegar à saída.
6. Se o jogador tiver moedas suficientes, ele pode usar o altar na saída para comprar +1 dano por 20 moedas.
7. O Guardião final bloqueia a saída; o dano da run reduz o HP dele, a defesa reduz o contra-ataque e a barra de HP dele aparece na HUD.
8. Se o HP do jogador chegar a 0, a run termina em derrota e a HUD mostra a mensagem final.
9. Ao derrotar o Guardião, o jogador recebe Insignia do Guardiao (+2 defesa) e depois pode usar a saída para vencer.
9. Se o jogador sair e voltar, o protótipo tenta restaurar a run ativa e posicionar o personagem na ultima sala salva.
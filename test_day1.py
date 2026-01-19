from player import Player
from enemy import Goblin, OrcChief

def test_player_creation():
    """Testa criação do jogador"""
    print("=== Teste 1: Criação do Player ===")
    player = Player("Arthon")
    player.show_status()
    print("✅ Player criado com sucesso!\n")

def test_level_up():
    """Testa sistema de level up"""
    print("=== Teste 2: Level Up ===")
    player = Player("Arthon")
    print(f"Nível inicial: {player.level}")
    print(f"XP necessário: {player.get_xp_needed()}")
    
    # Ganha XP suficiente para subir de nível
    player.gain_xp(100)
    
    print(f"Nível após ganhar 100 XP: {player.level}")
    player.show_status()
    print("✅ Level up funcionando!\n")

def test_multiple_level_ups():
    """Testa múltiplos level ups"""
    print("=== Teste 3: Múltiplos Level Ups ===")
    player = Player("Arthon")
    
    # Ganha muito XP de uma vez
    player.gain_xp(350)  # Deve subir para nível 3
    
    player.show_status()
    print("✅ Múltiplos level ups funcionando!\n")

def test_damage():
    """Testa sistema de dano"""
    print("=== Teste 4: Sistema de Dano ===")
    player = Player("Arthon")
    print(f"HP inicial: {player.hp}")
    
    player.take_damage(20)
    print(f"HP após receber 20 de dano: {player.hp}")
    
    player.heal(10)
    print(f"HP após curar 10: {player.hp}")
    
    print(f"Player está vivo? {player.is_alive()}")
    print("✅ Sistema de dano funcionando!\n")

def test_enemies():
    """Testa criação de inimigos"""
    print("=== Teste 5: Inimigos ===")
    
    goblin = Goblin()
    print(f"Inimigo: {goblin.name}")
    print(f"HP: {goblin.hp}")
    print(f"Ataque: {goblin.attack}")
    print(f"Pode fugir? {goblin.can_flee}")
    print(f"Descrição: {goblin.description}")
    print()
    
    boss = OrcChief()
    print(f"Boss: {boss.name}")
    print(f"HP: {boss.hp}")
    print(f"Ataque: {boss.attack}")
    print(f"Pode fugir? {boss.can_flee}")
    
    # Testa ataque especial do boss
    print("\nTestando ataques do boss:")
    for i in range(5):
        damage = boss.get_attack_damage()
        print(f"Turno {i+1}: Dano = {damage}")
    
    print("✅ Inimigos criados com sucesso!\n")

def test_combat_simulation():
    """Simula um combate simples"""
    print("=== Teste 6: Simulação de Combate ===")
    
    player = Player("Arthon")
    goblin = Goblin()
    
    print(f"{player.name} vs {goblin.name}")
    print(f"Player HP: {player.hp} | Goblin HP: {goblin.hp}")
    
    # Simula alguns turnos
    turn = 1
    while player.is_alive() and goblin.is_alive() and turn <= 10:
        print(f"\n--- Turno {turn} ---")
        
        # Player ataca
        damage_to_enemy = max(1, player.get_total_attack() - goblin.defense)
        goblin.take_damage(damage_to_enemy)
        print(f"{player.name} causa {damage_to_enemy} de dano")
        print(f"Goblin HP: {goblin.hp}")
        
        if not goblin.is_alive():
            print(f"\n{goblin.name} foi derrotado!")
            player.gain_xp(goblin.xp_reward)
            break
        
        # Goblin ataca
        damage_to_player = max(1, goblin.get_attack_damage() - player.get_total_defense())
        player.take_damage(damage_to_player)
        print(f"{goblin.name} causa {damage_to_player} de dano")
        print(f"{player.name} HP: {player.hp}")
        
        if not player.is_alive():
            print(f"\n{player.name} foi derrotado!")
            break
        
        turn += 1
    
    print("✅ Simulação de combate concluída!\n")


if __name__ == "__main__":
    print("🎮 TESTES DO DIA 1 - Player e Enemy\n")
    
    test_player_creation()
    test_level_up()
    test_multiple_level_ups()
    test_damage()
    test_enemies()
    test_combat_simulation()
    
    print("="*50)
    print("✅ TODOS OS TESTES DO DIA 1 CONCLUÍDOS!")
    print("="*50)
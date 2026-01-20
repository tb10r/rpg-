from player import Player
from items import rusty_sword, simple_shield, Weapon, Shield

def test_equip_weapon():
    """Testa equipar arma"""
    print("=== Teste 1: Equipar Arma ===")
    player = Player("Arthon")
    
    print(f"Ataque inicial: {player.get_total_attack()}")
    
    player.equip_weapon(rusty_sword)
    
    print(f"Ataque com espada: {player.get_total_attack()}")
    assert player.get_total_attack() == 13 + 3  # base agora é 13
    print("✅ Arma equipada com sucesso!\n")

def test_equip_shield():
    """Testa equipar escudo"""
    print("=== Teste 2: Equipar Escudo ===")
    player = Player("Arthon")
    
    print(f"Defesa inicial: {player.get_total_defense()}")
    
    player.equip_shield(simple_shield)
    
    print(f"Defesa com escudo: {player.get_total_defense()}")
    assert player.get_total_defense() == 6 + 2  # base agora é 6
    print("✅ Escudo equipado com sucesso!\n")

def test_replace_weapon():
    """Testa trocar de arma"""
    print("=== Teste 3: Trocar Arma ===")
    player = Player("Arthon")
    
    # Equipa primeira arma
    player.equip_weapon(rusty_sword)
    
    # Cria segunda arma
    strong_sword = Weapon("Espada Forte", attack_bonus=5, description="Uma espada poderosa")
    
    # Troca de arma
    player.equip_weapon(strong_sword)
    
    assert player.equipped_weapon == strong_sword
    assert player.get_total_attack() == 13 + 5
    print("✅ Troca de arma funcionando!\n")

def test_unequip_items():
    """Testa desequipar itens"""
    print("=== Teste 4: Desequipar Itens ===")
    player = Player("Arthon")
    
    player.equip_weapon(rusty_sword)
    player.equip_shield(simple_shield)
    
    print(f"Com equipamentos: Ataque={player.get_total_attack()}, Defesa={player.get_total_defense()}")
    
    player.unequip_weapon()
    player.unequip_shield()
    
    print(f"Sem equipamentos: Ataque={player.get_total_attack()}, Defesa={player.get_total_defense()}")
    
    assert player.equipped_weapon is None
    assert player.equipped_shield is None
    assert player.get_total_attack() == 13
    assert player.get_total_defense() == 6
    print("✅ Desequipar funcionando!\n")

def test_equipment_with_level_up():
    """Testa equipamentos após subir de nível"""
    print("=== Teste 5: Equipamentos + Level Up ===")
    player = Player("Arthon")
    
    player.equip_weapon(rusty_sword)
    player.equip_shield(simple_shield)
    
    print(f"Nível 1: Ataque={player.get_total_attack()}, Defesa={player.get_total_defense()}")
    
    player.gain_xp(100)  # Sobe para nível 2
    
    print(f"Nível 2: Ataque={player.get_total_attack()}, Defesa={player.get_total_defense()}")
    
    # Nível 2: base_attack=10, base_defense=4
    assert player.equipped_weapon == rusty_sword
    assert player.equipped_shield == simple_shield
    print("✅ Equipamentos funcionam com level up!\n")

def test_attribute_distribution():
    """Testa sistema de distribuição de atributos"""
    print("=== Teste 6: Sistema de Atributos ===")
    player = Player("Arthon")
    
    print(f"Atributos iniciais:")
    print(f"  Força: {player.strength} → Ataque: {player.base_attack}")
    print(f"  Vitalidade: {player.vitality} → HP: {player.max_hp}")
    print(f"  Agilidade: {player.agility} → Defesa: {player.base_defense}")
    
    # Verifica cálculos
    assert player.base_attack == 3 + (5 * 2)  # 13
    assert player.max_hp == 30 + (5 * 10)     # 80
    assert player.base_defense == 1 + (5 * 1) # 6
    
    print("✅ Sistema de atributos funcionando!\n")


if __name__ == "__main__":
    print("🎮 TESTES DO DIA 2 - Equipamentos\n")
    
    test_equip_weapon()
    test_equip_shield()
    test_replace_weapon()
    test_unequip_items()
    test_equipment_with_level_up()
    test_equipment_with_level_up()
    test_attribute_distribution()

    print("="*50)
    print("✅ TODOS OS TESTES DO DIA 2 CONCLUÍDOS!")
    print("="*50)
class Item:
    
    def __init__(self, name, item_type, description):
        self.name = name
        self.item_type = item_type  # "weapon", "shield", "consumable"
        self.description = description


class Weapon(Item):
    """Armas que aumentam ataque"""
    
    def __init__(self, name, attack_bonus, description):
        super().__init__(name, "weapon", description)
        self.attack_bonus = attack_bonus


class Shield(Item):
    """Escudos que aumentam defesa"""
    
    def __init__(self, name, defense_bonus, description):
        super().__init__(name, "shield", description)
        self.defense_bonus = defense_bonus


# Instâncias dos itens do jogo
rusty_sword = Weapon(
    name="Espada Enferrujada",
    attack_bonus=3,
    description="Uma espada velha, mas ainda afiada o suficiente."
)

simple_shield = Shield(
    name="Escudo Simples",
    defense_bonus=2,
    description="Um escudo de madeira reforçado com metal."
)
class Enemy:

    
    def __init__(self, name, hp, attack, defense, xp_reward, description):
        self.name = name
        self.max_hp = hp
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.xp_reward = xp_reward
        self.description = description
    
    def take_damage(self, amount):

        self.hp -= amount
        if self.hp < 0:
            self.hp = 0
    
    def is_alive(self):
        return self.hp > 0
    
    def get_attack_damage(self):
        return self.attack


class Goblin(Enemy):
    
    def __init__(self):
        super().__init__(
            name="Goblin",
            hp=30,
            attack=6,
            defense=2,
            xp_reward=40,
            description="Um goblin pequeno, mas rápido, segura uma lâmina enferrujada."
        )
        self.can_flee = True


class OrcChief(Enemy):
    
    def __init__(self):
        super().__init__(
            name="Orc Chief",
            hp=80,
            attack=12,
            defense=5,
            xp_reward=120,
            description="Um orc enorme bloqueia a passagem, com cicatrizes de batalhas antigas."
        )
        self.can_flee = False
        self.turn_counter = 0
    
    def get_attack_damage(self):
        self.turn_counter += 1
        
        if self.turn_counter % 3 == 0:
            print(f"\n⚠️  {self.name} usa ATAQUE PODEROSO!")
            return self.attack * 2
        
        return self.attack
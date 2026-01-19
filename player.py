class Player:

    def __init__(self,name):
        self.name = name
        self.level = 1
        self.xp = 0
        self.max_hp = 50
        self.hp = self.max_hp
        self.base_attack = 8
        self.base_defense = 3
        self.inventory = []
        self.position = "1"
        self.equipped_weapon = None
        self.equipped_shield = None

    def get_xp_needed(self):

        return self.level * 100
    
    def gain_xp(self, amount):

        self.xp += amount
        print(f"\n+{amount}xp")

        while self.xp >= self.get_xp_needed():
            self.level_up()
    
    def level_up(self):
        
        self.xp -= self.get_xp_needed()
        self.level += 1

        self.max_hp += 10
        self.base_attack += 2
        self.base_defense += 1

        self.hp = self.max_hp

        print(f"\n✨ Você subiu para o nível {self.level}! ✨")
        print(f"HP máximo: {self.max_hp}")
        print(f"Ataque: {self.get_total_attack()}")
        print(f"Defesa: {self.get_total_defense()}")
        print("Seu HP foi totalmente restaurado!")

    def take_damage(self,amount):

        self.hp -= amount
        if self.hp < 0:
            self.hp = 0

    def heal(self,amount):

        self.hp += amount
        if self.hp > self.max_hp:
            self.hp = self.max_hp

         
    def is_alive(self):

        return self.hp > 0
    
    def add_to_inventory(self,item):

        self.inventory.append(item)
        print(f"\n{item.name} adicionado ao inventário!")

    def remove_from_inventory(self, item):

        if item in self.inventory:
            self.inventory.remove(item)

    def get_total_attack(self):
        total = self.base_attack
        if self.equipped_weapon:
            total += self.equipped_weapon.attack_bonus
        return total
    
    def get_total_defense(self):
        total = self.base_defense
        if self.equipped_shield:
            total += self.equipped_shield.defense_bonus
        return total
    
    def show_status(self):
        print(f"\n{'='*40}")
        print(f"Nome: {self.name}")
        print(f"Nível: {self.level}")
        print(f"HP: {self.hp} / {self.max_hp}")
        print(f"Ataque: {self.get_total_attack()}")
        print(f"Defesa: {self.get_total_defense()}")
        print(f"XP: {self.xp} / {self.get_xp_needed()}")
        print(f"{'='*40}")
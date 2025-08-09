func resolve_combat(attacker: Card, defender: Card, attacking_player: Player, defending_player: Player):
	if attacker.position != "attack":
		return
	
	if defender == null: # Attaque directe
		defending_player.health -= attacker.atk
		return
	
	if defender.is_face_down:
		defender.is_face_down = false
		defender.position = "defense"
		# Activer effet de lancement si présent
	
	if defender.position == "attack":
		if attacker.atk > defender.atk:
			defending_player.health -= attacker.atk - defender.atk
			move_to_graveyard(defender, defending_player)
		elif attacker.atk < defender.atk:
			attacking_player.health -= defender.atk - attacker.atk
			move_to_graveyard(attacker, attacking_player)
		else:
			move_to_graveyard(attacker, attacking_player)
			move_to_graveyard(defender, defending_player)
	else: # Défense
		if attacker.atk > defender.def:
			move_to_graveyard(defender, defending_player)
			if Card.EsisarienAttribute.PERCANT in attacker.attributes:
				defending_player.health -= attacker.atk - defender.def
		elif attacker.atk < defender.def:
			attacking_player.health -= defender.def - attacker.atk

func move_to_graveyard(card: Card, p: Player):
	var index = p.esisarien_field.find(card)
	if index != -1:
		p.esisarien_field[index] = null
		p.graveyard.append(card)

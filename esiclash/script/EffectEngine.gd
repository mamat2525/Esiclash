# EffectEngine.gd
extends Node

signal effect_applied(card, effect) # Pour synchronisation ou UI

func apply_effect(card: Card, effect: Dictionary, source_player: Player, target_player: Player):
	rpc("sync_effect", card.id, effect, source_player, target_player) # true si joueur local
	match effect["type"]:
		"search":
			search_deck(source_player, effect.get("archetype", ""), effect.get("count", 1), effect.get("cost_change", 0))
		"stat_boost":
			boost_stats(card, effect.get("amount_atk", 0), effect.get("amount_def", 0), effect.get("duration", "permanent"))
		"add_attribute":
			add_attribute(card, effect.get("attribute"), effect.get("duration", "permanent"))
		"draw":
			draw_cards(source_player, effect.get("count", 1), effect.get("cost_change", 0))
		"prevent_destruction":
			prevent_destruction(card, effect.get("duration", "this_turn"))
		"destroy":
			destroy_card(target_player, effect.get("target_type", "esisarien"))
		"banish":
			banish_card(target_player, effect.get("target_type", "esisarien"))
		"negate_effect":
			negate_effect(card)
		"negate_attack":
			negate_attack(card)
		"direct_damage":
			deal_direct_damage(target_player, effect.get("amount", 0))
		"conditional":
			if check_condition(source_player, target_player, effect["condition"]):
				apply_effect(card, effect["sub_effect"], source_player, target_player)
		"end_turn":
			end_turn(source_player)
		"swap_control":
			swap_control(source_player, target_player, effect.get("target_1"), effect.get("target_2"))
	emit_signal("effect_applied", card, effect)

@rpc("any_peer", "call_remote")
func sync_effect(card_id: int, effect: Dictionary, source_player: Player, target_player: Player):
	var card = find_card_by_id(card_id, source_player)
	if card:
		apply_effect(card, effect, source_player, target_player)

func find_card_by_id(card_id: int, player: Player) -> Card:
	for field in [player.esisarien_field, player.object_field, player.hand, player.graveyard, player.banished]:
		for c in field:
			if c and c.id == card_id:
				return c
	return null

# Implémentation des effets
func search_deck(player: Player, archetype: String, count: int, cost_change: int):
	var valid_cards = player.deck.filter(func(c): return archetype == "" or c.name.contains(archetype))
	for i in min(count, valid_cards.size()):
		var card = valid_cards[i]
		player.deck.erase(card)
		if cost_change != 0:
			# Modifier le coût (si applicable, à définir dans Card)
			pass
		player.hand.append(card)
		rpc("reveal_card", card.id) # Révéler à l’adversaire

func boost_stats(card: Card, atk: int, def: int, duration: String):
	card.atk += atk
	card.def += def
	if duration != "permanent":
		# Gérer la durée (ex: "this_turn" ou "opponent_turn")
		pass

func add_attribute(card: Card, attribute: int, duration: String):
	if not attribute in card.attributes:
		card.attributes.append(attribute)
	if duration != "permanent":
		# Gérer la durée
		pass

func draw_cards(player: Player, count: int, cost_change: int):
	for i in count:
		if player.hand.size() < 8 and player.deck.size() > 0:
			var card = player.deck.pop_back()
			if cost_change != 0:
				# Modifier le coût
				pass
			player.hand.append(card)

func prevent_destruction(card: Card, duration: String):
	card.is_invulnerable = true # Ajouter une propriété temporaire
	if duration == "this_turn":
		# Réinitialiser à la fin du tour
		pass

func destroy_card(player: Player, target_type: String):
	var field = player.esisarien_field if target_type == "esisarien" else player.object_field
	if target_type == "both":
		field = field + player.object_field
	for i in field.size():
		if field[i] != null:
			player.graveyard.append(field[i])
			field[i] = null
			break

func banish_card(player: Player, target_type: String):
	var field = player.esisarien_field if target_type == "esisarien" else player.object_field
	if target_type == "both":
		field = field + player.object_field
	for i in field.size():
		if field[i] != null:
			player.banished.append(field[i])
			field[i] = null
			break

func negate_effect(card: Card):
	card.effects = [] # Désactive tous les effets

func negate_attack(card: Card):
	card.can_attack = false

func deal_direct_damage(player: Player, amount: int):
	player.health -= amount

func check_condition(source_player: Player, target_player: Player, condition: Dictionary):
	if condition.has("archetype_on_field"):
		return source_player.esisarien_field.any(func(c): return c and c.name.contains(condition["archetype_on_field"]))
	return true

func end_turn(player: Player):
	# Logique pour passer au tour suivant
	pass

func swap_control(source_player: Player, target_player: Player, target_1: int, target_2: int):
	var card1 = source_player.esisarien_field[target_1]
	var card2 = target_player.esisarien_field[target_2]
	if card1 and card2:
		source_player.esisarien_field[target_1] = card2
		target_player.esisarien_field[target_2] = card1

# Synchronisation réseau
@rpc func reveal_card(card_id: int):
	pass

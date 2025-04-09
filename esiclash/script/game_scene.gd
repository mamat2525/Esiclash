extends Node2D

var player: Player = Player.new()
var opponent: Player = Player.new()
var current_turn: int = 0 # 0 = joueur local, 1 = adversaire
var opponent_id: int
var is_first: bool

# Références aux nœuds de l’interface utilisateur
@onready var hand_container = $PlayerField/HandContainer  # HBoxContainer pour la main
@onready var health_label = $PlayerField/HealthLabel       # Label pour les PV
@onready var energy_label = $PlayerField/EnergyLabel       # Label pour l’énergie
@onready var esisarien_slots = $PlayerField/EsisarienSlots # HBoxContainer pour les Esisariens
@onready var object_slots = $PlayerField/ObjectSlots       # HBoxContainer pour les Objets

func _ready():
	if is_first:
		current_turn = 0
	else:
		current_turn = 1
	initialize_game()
	update_ui()
	start_turn()

func initialize_game():
	# Remplir les decks (exemple)
	for i in range(30):
		var card = Card.new(i, "Esisarien " + str(i), Card.CardType.ESISARIEN)
		card.atk = randi() % 10 + 1
		card.def = randi() % 10 + 1
		player.deck.append(card)
	
	# Mélanger les decks
	player.deck.shuffle()
	
	# Piocher 5 cartes
	for i in 5:
		draw_card(player)

func update_ui():
	# Mise à jour des points de vie et de l’énergie
	health_label.text = "PV : " + str(player.health)
	energy_label.text = "Énergie : " + str(player.energy)
	
	# Mise à jour de la main
	hand_container.get_children().all(func(child): child.queue_free()) # Supprime les anciennes cartes
	for card in player.hand:
		var card_ui = create_card_ui(card)
		hand_container.add_child(card_ui)
	
	# Mise à jour des emplacements Esisarien
	for i in range(5):
		var slot = esisarien_slots.get_child(i)
		if player.esisarien_field[i]:
			slot.text = player.esisarien_field[i].name + " (" + str(player.esisarien_field[i].atk) + "/" + str(player.esisarien_field[i].def) + ")"
		else:
			slot.text = "Vide"
	
	# Mise à jour des emplacements Objet
	for i in range(5):
		var slot = object_slots.get_child(i)
		if player.object_field[i]:
			slot.text = player.object_field[i].name
		else:
			slot.text = "Vide"

# Fonction utilitaire pour créer une représentation visuelle d’une carte
func create_card_ui(card: Card) -> Control:
	var card_ui = Button.new() # Ou autre nœud selon vos besoins (ex: TextureRect)
	card_ui.text = card.name + " (" + str(card.atk) + "/" + str(card.def) + ")"
	card_ui.custom_minimum_size = Vector2(10, 10) # Taille minimale pour la carte
	return card_ui

func draw_card(p: Player):
	if p.hand.size() < 8 and p.deck.size() > 0:
		var card = p.deck.pop_back()
		p.hand.append(card)
		update_ui()

func start_turn():
	# Réinitialiser l'énergie
	if current_turn == 0:
		player.energy = 10
	else: opponent.energy = 10
	# Piocher une carte
	draw_card(player if current_turn == 0 else opponent)

# Synchronisation des actions avec l’adversaire via RPC
func play_card(card: Card, slot: int):
	rpc_id(opponent_id, "opponent_played_card", card.id, slot)
	# Logique locale pour poser la carte

@rpc("any_peer", "call_remote")
func opponent_played_card(card_id: int, slot: int):
	# Logique pour refléter l’action de l’adversaire
	pass

func summon_card(card: Card, slot: int, face_down: bool):
	if card.type == Card.CardType.ESISARIEN:
		player.esisarien_field[slot] = card
		card.is_face_down = face_down
		card.can_attack = card.has_attribute(Card.EsisarienAttribute.CHARGE) and not face_down
		if not face_down:
			card.trigger_effect("launch", player, opponent)

func resolve_combat(attacker: Card, defender: Card, attacking_player: Player, defending_player: Player):
	# Gestion de Rage
	if attacker.has_attribute(Card.EsisarienAttribute.RAGE):
		var rage_count = attacker.attributes.count(Card.EsisarienAttribute.RAGE)
		for i in rage_count:
			if defending_player.esisarien_field.any(func(c): return c != null):
				# Doit attaquer un Esisarien
				pass
	
	# Gestion de Perçant
	if attacker.has_attribute(Card.EsisarienAttribute.PERCANT) and defender and defender.position == "defense":
		if attacker.atk > defender.def:
			defending_player.health -= attacker.atk - defender.def
	
	# Gestion de Sniper
	if attacker.has_attribute(Card.EsisarienAttribute.SNIPER) and not defending_player.esisarien_field.any(func(c): return c and c.has_attribute(Card.EsisarienAttribute.SNIPER)):
		defending_player.health -= attacker.atk
	
	# Appliquer Dernier Souffle si détruit
	if defender and (defender.atk < attacker.atk or defender.def < attacker.atk):
		defender.trigger_effect("last_breath", defending_player, attacking_player)

func activate_card(card: Card):
	if card.type == Card.CardType.ACTION:
		if card.action_type == Card.ActionType.RAPIDE:
			# Peut être joué pendant le tour adverse
			pass
		elif card.action_type == Card.ActionType.LOURDE and current_turn == 0:
			# Uniquement pendant notre tour
			pass
		elif card.action_type == Card.ActionType.CONTRE:
			# En réponse à un effet
			pass
		card.trigger_effect("activation", player, opponent)
		player.graveyard.append(card)
		player.hand.erase(card)
	elif card.type == Card.CardType.ESISARIEN and card.position == "attack":
		card.position = "defense"
		card.trigger_effect("activation", player, opponent)

extends Control

var player: Player = Player.new()
var opponent: Player = Player.new()
var current_turn: bool = false # 0 = joueur local, 1 = adversaire
var opponent_id: int
var is_first: bool
#var card
# Références aux nœuds de l’interface utilisateur
@onready var hand_container = $PlayerField/HandContainer  # HBoxContainer pour la main
@onready var endOfRoundLabel = $"PlayerField/BarreVieAllié/fin du tour/Label"
@onready var opponentHand = $"PlayerField/opponentHand"

#var object_esiSlotsAllie : Slots
#var object_esiSlotsEnnemi : Slots
#var object_objSlotsAllie : Slots
#var object_objSlotsEnnemi : Slots
	
func _ready():
	player.init(Player.PlayerType.ALLIE, $PlayerField/EsisarienSlotsAllié, $PlayerField/ObjetSlotsAllié)
	opponent.init(Player.PlayerType.ENNEMIE, $PlayerField/EsisarienSlotsEnnemi, $PlayerField/ObjetSlotsEnnemi)
	
	ServerHandeler.cardAddedInHandSignal.connect(draw_card)
	ServerHandeler.ennemiPlacedCardSignal.connect(ennemiPlacedCard)
	ServerHandeler.ennemiUpdateCardInHandSignal.connect(opponentHand.setCard)
	ServerHandeler.startOfRoundSignal.connect(_on_start_of_round)
	
	
	#object_esiSlotsAllie = Slots.new($PlayerField/EsisarienSlotsAllié, Card.CardType.ESISARIEN, Slots.JoueurType.ALLIE)
	#object_esiSlotsEnnemi = Slots.new($PlayerField/EsisarienSlotsEnnemi, Card.CardType.ESISARIEN, Slots.JoueurType.ENNEMI)
	#object_objSlotsAllie = Slots.new($PlayerField/ObjetSlotsAllié, Card.CardType.OBJET, Slots.JoueurType.ALLIE)
	#object_objSlotsEnnemi = Slots.new($PlayerField/ObjetSlotsEnnemi, Card.CardType.OBJET, Slots.JoueurType.ENNEMI)
	
	
	#initialize_game()
	#update_ui()
	#start_turn()
	
	#for i in range(2):
		#player.esisarien_slots.placerCarte(Card.new((randi() % 70)+67), i)
		#opponent.esisarien_slots.placerCarte(Card.new((randi() % 70)+67), i)
	#
	#for i in range(2):
		#player.object_slots.placerCarte(Card.new((randi() % 42)+138),i)
		#opponent.object_slots.placerCarte(Card.new((randi() % 42)+138),i)
	
	
func updatePosCarte():
	var pos0 = (hand_container.size.x - (Card.baseSize.x+Card.espacementEntreCarte)*len(player.hand))/2 #position de la première carte
	for i in len(player.hand):
		player.hand[i].setPos(Vector2(pos0+(Card.baseSize.x+Card.espacementEntreCarte)*i,0))
		if i==len(player.hand)-1:
			player.hand[i].nextCard = null
		else:
			player.hand[i].nextCard = player.hand[i+1]
			
		if i==0:
			player.hand[i].beforeCard = null
		else:
			player.hand[i].beforeCard = player.hand[i-1]

#func initialize_game():
	## Remplir les decks (exemple)
	#for i in range(30):
		#var card = Card.new(randi() % 180)
		#player.deck.append(card)
	#
	## Mélanger les decks
	#player.deck.shuffle()
	#
	## Piocher 5 cartes
	#for i in 3:
		#draw_card(player)

func ennemiPlacedCard(cardId : int, slot : int, emplacement : int):
	var card = Card.new(cardId)
	if slot == 0:
		opponent.object_slots.placerCarte(card, emplacement)
	elif slot == 1:
		opponent.esisarien_slots.placerCarte(card, emplacement)
	else:
		push_error("impossible de placer la carte ennemi dans le slot : ", slot, " : ce slot ne correspond à rien")
		return
	

func update_ui():
	updatePosCarte()

func draw_card(cardId:int):
	print("draw card : ", cardId)
	var card = Card.new(cardId)
	player.hand.append(card)
	hand_container.add_child(card)
	card.connect("carteCliquee", _on_cardInHand_clique)
	update_ui()


func start_turn():
	# Réinitialiser l'énergie
	if current_turn:
		player.energy = 10
	else: opponent.energy = 10
	# Piocher une carte
	#draw_card(player if current_turn == 0 else opponent)

# Synchronisation des actions avec l’adversaire via RPC
func play_card(card: Card, slot: int):
	rpc_id(opponent_id, "opponent_played_card", card.id, slot)
	# Logique locale pour poser la carte

#@rpc("any_peer", "call_remote")
#func opponent_played_card(card_id: int, slot: int):
	# Logique pour refléter l’action de l’adversaire
#	pass

func summon_card(card: Card, slot: int, face_down: bool = false):
	print("carte:", card, " placé en :", slot, " retourné:", face_down)
	if card.type == Card.CardType.ESISARIEN:
		#object_esiSlotsAllie.slots[slot] = card
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
	if attacker.has_attribute(Card.EsisarienAttribute.PERCANT) and defender and defender.positionCombat == "defense":
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
		elif card.action_type == Card.ActionType.LOURDE and current_turn:
			# Uniquement pendant notre tour
			pass
		elif card.action_type == Card.ActionType.CONTRE:
			# En réponse à un effet
			pass
		card.trigger_effect("activation", player, opponent)
		player.graveyard.append(card)
		player.hand.erase(card)
	elif card.type == Card.CardType.ESISARIEN and card.positionCombat == "attack":
		card.positionCombat = "defense"
		card.trigger_effect("activation", player, opponent)

func _on_fin_du_tour_button_down() -> void:
	if current_turn:
		ServerHandeler.rpc("endOfRound", ServerHandeler.serveur.get_unique_id())
		endOfRoundLabel.set_text("tour de\nl'adversaire")

var cardInHandSelectionner :Node = null
	
func _on_cardInHand_clique(card:Card, focusGagne : bool):
	if focusGagne and current_turn:
		cardInHandSelectionner=card
		clearHovelay()
		if card.type == Card.CardType.ESISARIEN:
			for i in range(5):
				if player.esisarien_slots.slots[i] == null:
					player.esisarien_slots.placerHoverlayDisponible(i, card)
		elif card.type == Card.CardType.OBJET:
			for i in range(5):
				if player.esisarien_slots.slots[i] != null and player.object_slots.slots[i] == null:
					player.object_slots.placerHoverlayDisponible(i, card)
	elif card==cardInHandSelectionner:
		cardInHandSelectionner = null
		clearHovelay()

func clearHovelay():
	player.object_slots.supprHoverlay()
	player.esisarien_slots.supprHoverlay()
	opponent.object_slots.supprHoverlay()
	opponent.esisarien_slots.supprHoverlay()


func _on_card_placed(emplacement:int):
	var card = cardInHandSelectionner #comprends pas pourquoi, mais ca marche : cardInHandSelectionner passe à null quand on le remove_child, mais la var test garde une référence
	cardInHandSelectionner.get_parent().remove_child(cardInHandSelectionner)
	
	if card.type == Card.CardType.ESISARIEN:
		player.esisarien_slots.placerCarte(card, emplacement)
	elif card.type == Card.CardType.OBJET:
		player.object_slots.placerCarte(card, emplacement)
		
	player.hand.erase(card)
	card.disconnect("carteCliquee", _on_cardInHand_clique)
	update_ui()

func _on_start_of_round():
	current_turn = true
	endOfRoundLabel.set_text("Fin du\ntour")

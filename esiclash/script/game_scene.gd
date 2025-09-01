extends Control

var player: Player = Player.new()
var opponent: Player = Player.new()
var current_turn: bool = true
var opponent_id: int
var is_first: bool

# Références aux nœuds de l’interface utilisateur
@onready var hand_container = $PlayerField/HandContainer  # HBoxContainer pour la main
@onready var endOfRoundLabel = $"PlayerField/BarreVieAllié/fin du tour/Label"
@onready var opponentHand = $"PlayerField/opponentHand"
@onready var playerHealthBarre = $"PlayerField/BarreVieAllié"
@onready var ennemiHealthBarre = $"PlayerField/BarreVieEnnemi"
@onready var graveyard = $PlayerField/Graveyard
@onready var ennemiGraveyard = $PlayerField/ennemiGraveyard

var cardPreload = preload("res://scene/objets/card.tscn")

func _ready():
	player.init(Player.PlayerType.ALLIE, $PlayerField/EsisarienSlotsAllié, $PlayerField/ObjetSlotsAllié, hand_container)
	opponent.init(Player.PlayerType.ENNEMIE, $PlayerField/EsisarienSlotsEnnemi, $PlayerField/ObjetSlotsEnnemi, hand_container)

func _process(_delta: float) -> void:
	for message in ServerHandeler.getNewMessage():
		match message[0]:
			"drawCard":
				hand_container.draw_card(int(message[1]))
			"enemieUpdateCardInHand":
				opponentHand.setCard(int(message[1]))
			"startTurn":
				_on_start_of_round()
			"endTurn":
				_on_endOfTurn()
			"ennemiePlacedCard":
				ennemiPlacedCard(int(message[1]), int(message[2]), int(message[3]))
			"revealCard":
				opponent.esisarien_slots.slots[int(message[1])].set_card(int(message[2]))
				opponent.esisarien_slots.slots[int(message[1])].setFightPosition(CardUi.FightPosition.DEFENSE)
			"setFightPos":
				var joueur : Player
				if message[1] == "0":
					joueur = player
				elif message[1] == "1":
					joueur = opponent
				else:
					print_debug("joueur inconnu dans la réception du message setFightPos : ", message)
					continue
				
				if message[3] == "def":
					joueur.esisarien_slots.slots[int(message[2])].setFightPosition(CardUi.FightPosition.DEFENSE)
				elif message[3] == "atk":
					joueur.esisarien_slots.slots[int(message[2])].setFightPosition(CardUi.FightPosition.ATTACK)
				else:
					print_debug("position de combat inconnu : ", message)
			"updateHealth":
				if message[1] == "0":
					player.health = int(message[2])
					playerHealthBarre.update_health(int(message[2]))
				elif message[1] == "1":
					opponent.health = int(message[2])
					ennemiHealthBarre.update_health(int(message[2]))
				else:
					print_debug("joueur inconnu dans la réception du message updateHealth : ", message)
					continue
					
			"moveToGraveyard":
				print(message)
				if message[1] == "0":
					graveyard.addCard(player, Card.CardType.ESISARIEN, int(message[2]))
				elif message[1] == "1":
					ennemiGraveyard.addCard(opponent, Card.CardType.ESISARIEN, int(message[2]))
				else:
					print_debug("joueur inconnu dans la réception du message moveToGraveyard : ", message)
			_ :
				print_debug("message inconnu : ", message)





func ennemiPlacedCard(cardId : int, slot : int, emplacement : int):
	var card = cardPreload.instantiate()
	
	if slot == 0:
		opponent.esisarien_slots.placerCarte(card, emplacement)
	elif slot == 1:
		opponent.object_slots.placerCarte(card, emplacement)
		card.set_card(cardId)
	else:
		push_error("impossible de placer la carte ennemi dans le slot : ", slot, " : ce slot ne correspond à rien")
		return
	


func update_ui():
	hand_container.updatePosCarte()



func _on_fin_du_tour_button_down() -> void:
	if current_turn:
		ServerHandeler.client.put_utf8_string("endOfTurn")
		_on_endOfTurn()
		
func _on_endOfTurn():
	endOfRoundLabel.set_text("Tour de\nl'adversaire")
	current_turn = false
	for esi in opponent.esisarien_slots.slots:
		if esi != null and esi.reveler:
			esi.setFightPositon(CardUi.FightPosition.WAITACTION)

func clearHovelay():
	player.object_slots.supprHoverlay()
	player.esisarien_slots.supprHoverlay()
	opponent.object_slots.supprHoverlay()
	opponent.esisarien_slots.supprHoverlay()

func _on_start_of_round():
	current_turn = true
	endOfRoundLabel.set_text("Fin du\ntour")
	for esi in player.esisarien_slots.slots:
		if esi != null:
			if !esi.reveler:
				esi.peutReveler = true
			else:
				esi.peutAttack = true
				esi.setFightPosition(CardUi.FightPosition.WAITACTION)

var attakingCard : int = -1

func cardWantToFight(emplacement : int):
	attakingCard = emplacement
	print("want : ", emplacement)
	
func cardStopWantToFight(emplacement : int):
	if attakingCard == emplacement:
		attakingCard = -1
		print("stop : ", emplacement)
	
func ennemiIsSelected(emplacement : int):
	if attakingCard != -1:
		print("attack! ", attakingCard, " et ", emplacement)
		ServerHandeler.client.put_utf8_string("cardAttack:{0}:{1}".format([str(attakingCard), str(emplacement)]))
		player.esisarien_slots.slots[attakingCard].hasAttacked()
	else:
		print("ennemi mais vide")

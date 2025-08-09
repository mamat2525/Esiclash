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
			_ :
				print_debug("message inconnu : ", message)





func ennemiPlacedCard(cardId : int, slot : int, emplacement : int):
	var card = CardUi.new(cardId)
	if slot == 0:
		opponent.esisarien_slots.placerCarte(card, emplacement)
	elif slot == 1:
		opponent.object_slots.placerCarte(card, emplacement)
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

func clearHovelay():
	player.object_slots.supprHoverlay()
	player.esisarien_slots.supprHoverlay()
	opponent.object_slots.supprHoverlay()
	opponent.esisarien_slots.supprHoverlay()

func _on_start_of_round():
	current_turn = true
	endOfRoundLabel.set_text("Fin du\ntour")

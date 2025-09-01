extends Control

@onready var gamescene = $"/root/GameScene"

var inGraveYard : Array = []

func addCard(player : Player, type : Card.CardType, emplacement : int):
	print("add in garve yard")
	var card : CardUi = null
	if type == Card.CardType.ESISARIEN:
		card = player.esisarien_slots.slots[emplacement]
	elif type == Card.CardType.OBJET:
		card = player.objet_slots.slots[emplacement]
	else:
		print_debug("type incnnue dans addCard : ", type)
	card.reparent(self)
	inGraveYard.append(card)
	card.setPos(Vector2(0,0))
	card.placer = false
	
func hideAllOther():
	for i in range(len(inGraveYard)-1):
		inGraveYard[i].hide()
	inGraveYard[-1].show()

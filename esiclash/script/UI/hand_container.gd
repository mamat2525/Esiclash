extends Control

@onready var game_scene = $"/root/GameScene"

func updatePosCarte():
	var pos0 = (size.x - (CardUi.baseSize.x+CardUi.espacementEntreCarte)*len(game_scene.player.hand))/2 #position de la première carte
	for i in len(game_scene.player.hand):
		game_scene.player.hand[i].setPos(Vector2(pos0+(CardUi.baseSize.x+CardUi.espacementEntreCarte)*i,0))
		if i==len(game_scene.player.hand)-1:
			game_scene.player.hand[i].nextCard = null
		else:
			game_scene.player.hand[i].nextCard = game_scene.player.hand[i+1]
			
		if i==0:
			game_scene.player.hand[i].beforeCard = null
		else:
			game_scene.player.hand[i].beforeCard = game_scene.player.hand[i-1]


func draw_card(cardId:int):
	var card = CardUi.new(cardId)
	game_scene.player.hand.append(card)
	add_child(card)
	card.connect("carteCliquee", _on_cardInHand_clique)
	game_scene.update_ui()
	
	
var cardInHandSelectionner : Node = null

func _on_cardInHand_clique(card:CardUi, focusGagne : bool):
	if focusGagne and game_scene.current_turn:
		cardInHandSelectionner=card
		game_scene.clearHovelay()
		if card.type == Card.CardType.ESISARIEN:
			for i in range(5):
				if game_scene.player.esisarien_slots.slots[i] == null:
					game_scene.player.esisarien_slots.placerHoverlayDisponible(i, card)
		elif card.type == Card.CardType.OBJET:
			for i in range(5):
				if game_scene.player.esisarien_slots.slots[i] != null and game_scene.player.object_slots.slots[i] == null:
					game_scene.player.object_slots.placerHoverlayDisponible(i, card)
	elif card==cardInHandSelectionner:
		cardInHandSelectionner = null
		game_scene.clearHovelay()



func _on_card_placed(emplacement:int):
	var card = cardInHandSelectionner #comprends pas pourquoi, mais ca marche : cardInHandSelectionner passe à null quand on le remove_child, mais la var test garde une référence
	cardInHandSelectionner.get_parent().remove_child(cardInHandSelectionner)
	
	if card.type == Card.CardType.ESISARIEN:
		ServerHandeler.client.put_utf8_string("placedCard:{0}:0:{1}".format([str(game_scene.player.hand.find(card)), str(emplacement)]))
		game_scene.player.esisarien_slots.placerCarte(card, emplacement)
	elif card.type == Card.CardType.OBJET:
		ServerHandeler.client.put_utf8_string("placedCard:{0}:1:{1}".format([str(game_scene.player.hand.find(card)), str(emplacement)]))
		game_scene.player.object_slots.placerCarte(card, emplacement)
		
	game_scene.player.hand.erase(card)
	card.disconnect("carteCliquee", _on_cardInHand_clique)
	game_scene.update_ui()

class_name GameInstance
# contient la logique d'une partie

var player1 : Player = Player.new()
var player2 : Player = Player.new()
var current_turn : int = 0 # 0 : joueur 1; 1 : joueur 2
var roomId : int

func _init(peer1 : StreamPeerTCP, peer2 : StreamPeerTCP, roomId_ : int):
	player1.peer = peer1
	player2.peer = peer2
	roomId = roomId_

	for i in range(30):
		var card = randi() % 180
		player1.deck.append(card)
	for i in range(30):
		var card = randi() % 180
		player2.deck.append(card)
	
	# Mélanger les decks
	player1.deck.shuffle()
	player2.deck.shuffle()
	
	# Piocher 5 cartes
	draw_card(player1, 5)
	draw_card(player2, 5)
		
	
	if randi() % 2:
		current_turn = 0
		player1.peer.put_utf8_string("startTurn")
		player2.peer.put_utf8_string("endTurn")
	else:
		current_turn = 1
		player2.peer.put_utf8_string("startTurn")
		player1.peer.put_utf8_string("endTurn")

func newMessage(player : int, mess : Array):
	match mess[0]:
		"placedCard": # [joueur : <0: joueur 1; 1: joueur2>, "placedCard", emplacementInHand, slot <0:objet, 1:esisarien>, emplacement]
			if verifCardCanBePlaced(mess):
				var joueur : Player
				if player == 0:
					joueur = player1
				else:
					joueur = player2
				
				if mess[2] == "0":
					joueur.esisarien[int(mess[3])] = joueur.hand[int(mess[2])]
				else:
					joueur.objet[int(mess[3])] = joueur.hand[int(mess[2])]
				if player == 0:
					player2.peer.put_utf8_string("ennemiePlacedCard:{0}:{1}:{2}".format([joueur.hand[int(mess[1])], mess[2], mess[3]]))
					player2.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player1.hand) - 1))
				else:
					player1.peer.put_utf8_string("ennemiePlacedCard:{0}:{1}:{2}".format([joueur.hand[int(mess[1])], mess[2], mess[3]]))
					player1.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player2.hand) - 1))
				joueur.hand.remove_at(int(mess[1]))
			else:#TODO géré si la carte ne peut pas être placé -> (tout?) synchroniser
				print_debug("[serveur/GameInstance] la carte ne peux pas être placé : ", mess)
		"endOfTurn":
			if player == 0 and current_turn == 0:
				current_turn = 1
				draw_card(player2)
				player2.peer.put_utf8_string("startTurn")
				player1.peer.put_utf8_string("endTurn")
			elif player == 1 and current_turn == 1:
				current_turn = 0
				draw_card(player1)
				player1.peer.put_utf8_string("startTurn")
				player2.peer.put_utf8_string("endTurn")
			else:
				print_debug("[serveur/GameInstane] impossible de changer de tour : c'est pas à ce joueur de jouer : ", player, " et ", current_turn)
		_ : 
			print_debug("[serveur/GameInstance] message inconnu : ", mess)

func draw_card(p: Player, nbCard : int = 1):
	for i in range(nbCard):
		if p.hand.size() < 8 and p.deck.size() > 0:
			var card = p.deck.pop_back()
			p.hand.append(card)
			#print_debug(p.playerId)
			p.peer.put_utf8_string("drawCard:"+str(card))
	if p == player1:
		player2.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player1.hand)))
	else:
		player1.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player2.hand)))

func verifCardCanBePlaced(_mess): #TODO
	return true

################################################


#func start_turn():
	## Réinitialiser l'énergie
	#if current_turn:
		#player.energy = 10
	#else: opponent.energy = 10
	# Piocher une carte
	#draw_card(player if current_turn == 0 else opponent)
	
	#
#func summon_card(card: Card, slot: int, face_down: bool = false):
	#print("carte:", card, " placé en :", slot, " retourné:", face_down)
	#if card.type == Card.CardType.ESISARIEN:
		##object_esiSlotsAllie.slots[slot] = card
		#card.is_face_down = face_down
		#card.can_attack = card.has_attribute(Card.EsisarienAttribute.CHARGE) and not face_down
		#if not face_down:
			#card.trigger_effect("launch", player, opponent)
#
#func resolve_combat(attacker: Card, defender: Card, attacking_player: Player, defending_player: Player):
	## Gestion de Rage
	#if attacker.has_attribute(Card.EsisarienAttribute.RAGE):
		#var rage_count = attacker.attributes.count(Card.EsisarienAttribute.RAGE)
		#for i in rage_count:
			#if defending_player.esisarien_field.any(func(c): return c != null):
				## Doit attaquer un Esisarien
				#pass
	#
	## Gestion de Perçant
	#if attacker.has_attribute(Card.EsisarienAttribute.PERCANT) and defender and defender.positionCombat == "defense":
		#if attacker.atk > defender.def:
			#defending_player.health -= attacker.atk - defender.def
	#
	## Gestion de Sniper
	#if attacker.has_attribute(Card.EsisarienAttribute.SNIPER) and not defending_player.esisarien_field.any(func(c): return c and c.has_attribute(Card.EsisarienAttribute.SNIPER)):
		#defending_player.health -= attacker.atk
	#
	## Appliquer Dernier Souffle si détruit
	#if defender and (defender.atk < attacker.atk or defender.def < attacker.atk):
		#defender.trigger_effect("last_breath", defending_player, attacking_player)
#
#func activate_card(card: Card):
	#if card.type == Card.CardType.ACTION:
		#if card.action_type == Card.ActionType.RAPIDE:
			## Peut être joué pendant le tour adverse
			#pass
		#elif card.action_type == Card.ActionType.LOURDE and current_turn:
			## Uniquement pendant notre tour
			#pass
		#elif card.action_type == Card.ActionType.CONTRE:
			## En réponse à un effet
			#pass
		#card.trigger_effect("activation", player, opponent)
		#player.graveyard.append(card)
		#player.hand.erase(card)
	#elif card.type == Card.CardType.ESISARIEN and card.positionCombat == "attack":
		#card.positionCombat = "defense"
		#card.trigger_effect("activation", player, opponent)

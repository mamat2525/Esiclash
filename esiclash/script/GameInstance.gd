class_name GameInstance
# contient la logique d'une partie
extends Node

var player1 : Player = Player.new()
var player2 : Player = Player.new()
var current_turn : int = 0 # 0 : joueur 1; 1 : joueur 2
var roomId : int

func _init(client1 : Client, client2 : Client, roomId_ : int):
	player1.client = client1
	player2.client = client2
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
		player1.client.peer.put_utf8_string("startTurn")
		player2.client.peer.put_utf8_string("endTurn")
	else:
		current_turn = 1
		player2.client.peer.put_utf8_string("startTurn")
		player1.client.peer.put_utf8_string("endTurn")

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
					player2.client.peer.put_utf8_string("ennemiePlacedCard:{0}:{1}:{2}".format([joueur.hand[int(mess[1])], mess[2], mess[3]]))
					player2.client.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player1.hand) - 1))
				else:
					player1.client.peer.put_utf8_string("ennemiePlacedCard:{0}:{1}:{2}".format([joueur.hand[int(mess[1])], mess[2], mess[3]]))
					player1.client.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player2.hand) - 1))
				joueur.hand.remove_at(int(mess[1]))
			else:#TODO géré si la carte ne peut pas être placé -> (tout?) synchroniser
				print_debug("[serveur/GameInstance] la carte ne peux pas être placé : ", mess)
		"endOfTurn":
			if player == 0 and current_turn == 0:
				current_turn = 1
				draw_card(player2)
				player2.client.peer.put_utf8_string("startTurn")
				player1.client.peer.put_utf8_string("endTurn")
			elif player == 1 and current_turn == 1:
				current_turn = 0
				draw_card(player1)
				player1.client.peer.put_utf8_string("startTurn")
				player2.client.peer.put_utf8_string("endTurn")
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
			p.client.peer.put_utf8_string("drawCard:"+str(card))
	if p == player1:
		player2.client.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player1.hand)))
	else:
		player1.client.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player2.hand)))

func verifCardCanBePlaced(_mess): #TODO
	return true

class_name GameInstance
# contient la logique d'une partie

var player1 : Player = Player.new()
var player2 : Player = Player.new()
var current_turn : int = 0 # 0 : joueur 1; 1 : joueur 2
var roomId : int

func _init(peer1 : StreamPeerTCP, peer2 : StreamPeerTCP, roomId_ : int):
	player1.peer = peer1
	player2.peer = peer2
	
	player1.opponent = player2
	player2.opponent = player1
	
	roomId = roomId_

	for i in range(30):
		var card = Card.new(randi() % 180)
		player1.deck.append(card)
	for i in range(30):
		var card = Card.new(randi() % 180)
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
	var joueur : Player
	if player == 0:
		joueur = player1
	else:
		joueur = player2
	match mess[0]:
		"placedCard": # [joueur : <0: joueur 1; 1: joueur2>, "placedCard", emplacementInHand, slot <0:objet, 1:esisarien>, emplacement]
			if verifCardCanBePlaced(mess):
				var cardId : String
				if mess[2] == "0":
					cardId = "0"
					joueur.esisarien[int(mess[3])] = joueur.hand[int(mess[1])]
					joueur.esisarien[int(mess[3])].is_face_down = true
				else:
					cardId = str(joueur.hand[int(mess[1])].id)
					joueur.objet[int(mess[3])] = joueur.hand[int(mess[1])]
				
				joueur.opponent.peer.put_utf8_string("ennemiePlacedCard:{0}:{1}:{2}".format([cardId, mess[2], mess[3]]))
				joueur.opponent.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player1.hand) - 1))
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
		"revealCard":
			if verifCardCanBeRevaeled(mess):
				#TODO : mettre à jour que la carte a été retourné
				joueur.esisarien[int(mess[1])].is_face_down = false
				joueur.esisarien[int(mess[1])].positionCombat = Card.FightPosition.DEFENSE
				joueur.opponent.peer.put_utf8_string("revealCard:{0}:{1}".format([mess[1], str(joueur.esisarien[int(mess[1])].id)]))
		"setFightPos":
			if verifCardCanSetFightPos(mess):
				#TODO : mettre à jour que la carte a changé de position de combat
				
				if mess[2] == "atk":
					joueur.esisarien[int(mess[1])].positionCombat = Card.FightPosition.ATTACK
				elif mess[2] == "def":
					joueur.esisarien[int(mess[1])].positionCombat = Card.FightPosition.DEFENSE
				else:
					print_debug("[serveur] Position de combat inconnu dans setFightPos : ", mess)
				joueur.opponent.peer.put_utf8_string("setFightPos:1:{0}:{1}".format([mess[1], mess[2]])) # setFightPos:<allie : 0; ennemie : 1>:<emplacement dans le slots esisariens>:<"def" ou "atk">
		"cardAttack":
			if verifCardCanAttack(mess):
				print("à l'attaque !")
				joueur.opponent.peer.put_utf8_string("setFightPos:1:{0}:atk".format([mess[1]]))
				resolve_combat(int(mess[1]), int(mess[2]), joueur)
		_ : 
			print_debug("[serveur/GameInstance] message inconnu : ", mess)

func draw_card(p: Player, nbCard : int = 1):
	for i in range(nbCard):
		if p.hand.size() < 8 and p.deck.size() > 0:
			var card = p.deck.pop_back()
			p.hand.append(card)
			#print_debug(p.playerId)
			p.peer.put_utf8_string("drawCard:"+str(card.id))
	if p == player1:
		player2.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player1.hand)))
	else:
		player1.peer.put_utf8_string("enemieUpdateCardInHand:"+str(len(player2.hand)))

func verifCardCanBePlaced(_mess): #TODO
	return true

func verifCardCanBeRevaeled(_mess): #TODO
	return true

func verifCardCanSetFightPos(_mess): #TODO
	return true
	
func verifCardCanAttack(_mess): #TODO
	return true
################################################


func resolve_combat(atkEmplacement : int, defEmplacement: int, player : Player):
	var attacker : Card = player.esisarien[atkEmplacement]
	var defender : Card = player.opponent.esisarien[defEmplacement]
	
	
	#if defender == null: # Attaque directe
		#defending_player.health -= attacker.atk
		#return
	#
	if defender.is_face_down:
		print("ok, on doit réveler")
		defender.is_face_down = false
		defender.positionCombat = Card.FightPosition.DEFENSE
		player.opponent.peer.put_utf8_string("setFightPos:0:{0}:{1}".format([str(defEmplacement), "def"])) # setFightPos:<allie : 0; ennemie : 1>:<emplacement dans le slots esisariens>:<"def" ou "atk">
		player.peer.put_utf8_string("revealCard:{0}:{1}".format([str(defEmplacement), str(defender.id)]))
		player.peer.put_utf8_string("setFightPos:1:{0}:{1}".format([str(defEmplacement), "def"])) # setFightPos:<allie : 0; ennemie : 1>:<emplacement dans le slots esisariens>:<"def" ou "atk">
		
		# TODO : Activer effet de lancement si présent
	
	##TODO : gestion de la vie
	
	if defender.positionCombat == Card.FightPosition.ATTACK:
		print("cas vs attack")
		if attacker.atk > defender.atk:
			print("victoire atk")
			player.opponent.removeHealth(attacker.atk - defender.atk)
			move_to_graveyard(defEmplacement, player.opponent)
		elif attacker.atk < defender.atk:
			print("victoire def")
			player.removeHealth(defender.atk - attacker.atk)
			move_to_graveyard(atkEmplacement, player)
		else:
			print("egalite")
			move_to_graveyard(atkEmplacement, player)
			move_to_graveyard(defEmplacement, player.opponent)
	elif defender.positionCombat == Card.FightPosition.DEFENSE:
		print("cas vs defense")
		if attacker.atk > defender.def:
			print("victoire atk")
			move_to_graveyard(defEmplacement, player.opponent)
			if Card.EsisarienAttribute.PERCANT in attacker.attributes:
				player.opponent.removeHealth(attacker.atk - defender.def)
			
		elif attacker.atk < defender.def:
			print("victoire def")
			player.removeHealth(defender.def - attacker.atk)
		else:
			print("egalité, rien ne se passe")
	else:
		print_debug("[serveur] position de combat inconnu dans resolve_combat")
	
	print("fin du combat")

func move_to_graveyard(emplacement : int, player: Player):
	## TODO : gestion des objets
	print("[serveur] move to graveyard")
	player.graveyard.append(player.esisarien[emplacement])
	player.esisarien[emplacement] = null
	player.peer.put_utf8_string("moveToGraveyard:0:{0}".format([str(emplacement)]))
	player.opponent.peer.put_utf8_string("moveToGraveyard:1:{0}".format([str(emplacement)]))


func resolve_combat2(attacker: Card, defender: Card, attacking_player: Player, defending_player: Player):
	# Gestion de Rage
	if attacker.has_attribute(Card.EsisarienAttribute.RAGE):
		var rage_count = attacker.attributes.count(Card.EsisarienAttribute.RAGE)
		for i in rage_count:
			if defending_player.esisarien.any(func(c): return c != null):
				# Doit attaquer un Esisarien
				pass
	
	# Gestion de Perçant
	if attacker.has_attribute(Card.EsisarienAttribute.PERCANT) and defender and defender.positionCombat == Card.FightPosition.DEFENSE:
		if attacker.atk > defender.def:
			defending_player.health -= attacker.atk - defender.def
	
	# Gestion de Sniper
	if attacker.has_attribute(Card.EsisarienAttribute.SNIPER) and not defending_player.esisarien_field.any(func(c): return c and c.has_attribute(Card.EsisarienAttribute.SNIPER)):
		defending_player.health -= attacker.atk
	
	# Appliquer Dernier Souffle si détruit
	if defender and (defender.atk < attacker.atk or defender.def < attacker.atk):
		defender.trigger_effect("last_breath", defending_player, attacking_player)


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

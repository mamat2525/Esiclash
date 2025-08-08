extends Node

var server := TCPServer.new()
var clients: Array = []  # id -> StreamPeerTCP

var port := 4242
const messageDelimiter = ':'

var rooms = {}   # Dictionnaire : room_id -> [peer_id_1, peer_id_2]
var gameInstance = {}
var waitingListe : Array = []



func _ready():
	var err = server.listen(port)
	if err != OK:
		print("Erreur lors du démarrage du serveur :", err)
		return
	print("Serveur en écoute sur le port ", port)
	get_tree().root.remove_child(ServerHandeler)

func _process(_delta):
	# Nouvelle connexion
	if server.is_connection_available():
		var new_client = Client.new(server.take_connection())
		clients.append(new_client)
		print("Nouveau client connecté :", new_client)

	# Gérer chaque client
	var disconnectedClient = [] 
	
	for client : Client in clients:

		# Vérifier l'état de connexion
		if client.peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("Client déconnecté : ", client.peer)
			disconnectedClient.append(client) # on ne peut pas faire clients.erase(client) dans le for, on le traite après
			
			#TODO : prendre en compte si le joueur est dans une room (faire un timer pour lui laisser le temps de revenir ?)
			#TODO : prendre en compte si le joueur est dans la file d'attente
			continue

		# Lire messages s'il y en a
		if client.peer.get_available_bytes() > 0:
			var message = client.peer.get_utf8_string().split(messageDelimiter)
			if client.roomId==-1: # le client n'est pas dans une room, on le traite directement
				match message[0] :
					"wantToPlay" :
						print("[serveur] le client : ", client.peer, "veux jouer")
						client.peer.put_utf8_string("waitOk")
						waitingListe.append(client)
						if len(waitingListe) > 1:
							var joueur1 = waitingListe.pop_front()
							var joueur2 = waitingListe.pop_front()
							if joueur2 == null or joueur1==null:
								print_debug("[serveur] hmm joueur 1 ou joueur 2 null ...")
								if joueur1 != null:
									waitingListe.append(joueur1)
								if joueur2 != null:
									waitingListe.append(joueur2)
							else:
								create_room(joueur1, joueur2)
						
					_ : print("[serveur] message recu de {0} est inconnu : {1} (message complet : {2})".format([str(client.peer), message[0], str(message)]))
			else: # le client est dans une room, on laisse l'instance de jeu la traiter
				if client == gameInstance[client.roomId].player1.client:
					gameInstance[client.roomId].newMessage(0, message)
				elif client == gameInstance[client.roomId].player2.client:
					gameInstance[client.roomId].newMessage(1, message)
				else:
					print_debug("[serveur] pb : le client n'est dans la room qu'il est sensé être")
			
	for client in disconnectedClient:
		clients.erase(client)





###################################################"




## Server.gd
#extends Node
#
#const PORT = 4242
#const MAX_PLAYERS = 100
#
#var players = {} # Dictionnaire : peer_id -> player_info
#var rooms = {}   # Dictionnaire : room_id -> [peer_id_1, peer_id_2]
#var gameInstance = {}
#var server : ENetMultiplayerPeer
#
#var waitingListe : Array = []
#
#func _ready():
	#
	#server = ENetMultiplayerPeer.new()
	#var err = server.create_server(PORT, MAX_PLAYERS)
	#if err != OK:
		#print("pas ok")
	#else:
		#multiplayer.multiplayer_peer = server
		#multiplayer.peer_connected.connect(player_connected)
		#multiplayer.peer_disconnected.connect(player_disconnected)
		#print("[serveur] Launched !")
		#get_tree().root.remove_child(ServerHandeler)
		#self.set_name("ServerHandeler")
#
#func player_connected(peer_id: int):
	#print("[serveur] Joueur connecté : ", peer_id)
	#players[peer_id] = {"name": "Joueur_" + str(peer_id), "ready": false}
	##rpc("update_lobby", players) # Envoie la liste des joueurs à tous les clients
#
#func player_disconnected(peer_id: int):
	#print("[serveur] Joueur déconnecté : ", peer_id)
	#players.erase(peer_id)
	#for room_id in rooms.keys():
		#if peer_id in rooms[room_id]:
			#rooms[room_id].erase(peer_id)
			#if rooms[room_id].empty():
				#rooms.erase(room_id)
			#else:
				#rpc_id(rooms[room_id][0], "opponent_disconnected")
	##rpc("update_lobby", players)
#
func create_room(joueur1: Client, joueur2:Client):
	var room_id = randi() # ID unique pour la room #TODO : faire un id vraiment unique...
	rooms[room_id] = [joueur1, joueur2]
	print("[serveur] room created : ", room_id, " :", joueur1, ", ", joueur2)
	
	joueur1.peer.put_utf8_string("joinRoom")
	joueur2.peer.put_utf8_string("joinRoom")
	
	joueur1.roomId = room_id
	joueur2.roomId = room_id
	
	gameInstance[room_id] = GameInstance.new(joueur1, joueur2, room_id)
#
#func _on_playerDrawCardSignal(roomId : int, playerId : int, cardId : int):
	#print(playerId, " draw card : ", cardId)
	#if rooms[roomId][0] == playerId:
		#print("its player 1 : {0} and {1}".format([str(rooms[roomId][0]), str(gameInstance[roomId].player1.playerId)]))
		#rpc_id(rooms[roomId][0], "cardAddedInHand", cardId)
		#rpc_id(rooms[roomId][1], "ennemiUpdateCardInHand", len(gameInstance[roomId].player2.hand))
	#else:
		#print("its player 2 : {0} and {1}".format([str(rooms[roomId][0]), str(gameInstance[roomId].player1.playerId)]))
		#rpc_id(rooms[roomId][1], "cardAddedInHand", cardId)
		#rpc_id(rooms[roomId][0], "ennemiUpdateCardInHand", len(gameInstance[roomId].player1.hand))
#
#func _on_playerStartTurnSignal(roomId : int, playerId : int):
	#pass
#
#func _on_playerEndTurnSignal(roomId : int, playerId : int):
	#pass
#
#func start_game(room_id: int):
	#var player_1 = rooms[room_id][0]
	#var player_2 = rooms[room_id][1]
	#rpc_id(player_1, "start_game", player_2, true)  # true = joueur 1 commence
	#rpc_id(player_2, "start_game", player_1, false) # false = joueur 2 attend
#
#@rpc("any_peer","call_remote","reliable")
func wantToPlay(peer_id:int):
	print("[serveur] ", peer_id, " want to play")
	rpc_id(peer_id, "waitOk")
	waitingListe.append(peer_id)
	if len(waitingListe) > 1:
		var joueur1 = waitingListe.pop_front()
		var joueur2 = waitingListe.pop_front()
		if joueur2 == null or joueur1==null:
			print("[serveur] hmm joueur 1 ou joueur 2 null ...")
			if joueur1 != null:
				waitingListe.append(joueur1)
			if joueur2 != null:
				waitingListe.append(joueur2)
		else:
			create_room(joueur1, joueur2)
#
#@rpc("any_peer","call_remote","reliable")	
#func waitOk():
	#pass
#
#@rpc("any_peer","call_remote","reliable")	
#func joinRoom(_roomId : int):
	#pass
#
#@rpc("authority","call_remote","reliable")
#func ennemiPlacedCard(cardId : int, slot : int):
	#pass
#
#@rpc("authority","call_remote","reliable")
#func ennemiUpdateCardInHand(nbCard : int):
	#pass
#
#@rpc("authority","call_remote","reliable")
#func cardAddedInHand(cardId : int):
	#pass
#
#@rpc("any_peer","call_remote","reliable")
#func nextTurn(room_id : int, _peer_id:int):
	#print("nextTurn")
#
#@rpc("any_peer","call_remote","reliable")
#func startOfRound():
	#pass

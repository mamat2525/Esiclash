# Server.gd
extends Node

const PORT = 4242
const MAX_PLAYERS = 100

var players = {} # Dictionnaire : peer_id -> player_info
var rooms = {}   # Dictionnaire : room_id -> [peer_id_1, peer_id_2]
var gameInstance = {}
var server : ENetMultiplayerPeer

var waitingListe : Array = []

func _ready():
	
	server = ENetMultiplayerPeer.new()
	var err = server.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		print("pas ok")
	else:
		multiplayer.multiplayer_peer = server
		multiplayer.peer_connected.connect(player_connected)
		multiplayer.peer_disconnected.connect(player_disconnected)
		print("[serveur] Launched !")
		get_tree().root.remove_child(ServerHandeler)
		self.set_name("ServerHandeler")

func player_connected(peer_id: int):
	print("[serveur] Joueur connecté : ", peer_id)
	players[peer_id] = {"name": "Joueur_" + str(peer_id), "ready": false}
	#rpc("update_lobby", players) # Envoie la liste des joueurs à tous les clients

func player_disconnected(peer_id: int):
	print("[serveur] Joueur déconnecté : ", peer_id)
	players.erase(peer_id)
	for room_id in rooms.keys():
		if peer_id in rooms[room_id]:
			rooms[room_id].erase(peer_id)
			if rooms[room_id].empty():
				rooms.erase(room_id)
			else:
				rpc_id(rooms[room_id][0], "opponent_disconnected")
	#rpc("update_lobby", players)

func create_room(joueur1: int, joueur2:int):
	var room_id = randi() # ID unique pour la room
	rooms[room_id] = [joueur1, joueur2]
	print("[serveur] room created : ", room_id, " :", joueur1, ", ", joueur2)
	
	
	rpc_id(joueur1, "joinRoom", room_id)
	rpc_id(joueur2, "joinRoom", room_id)
	
	gameInstance[room_id] = GameInstance.new(joueur1, joueur2, room_id)
	gameInstance[room_id].playerDrawCardSignal.connect(_on_playerDrawCardSignal)
	gameInstance[room_id].playerStartTurnSignal.connect(_on_playerStartTurnSignal)
	gameInstance[room_id].playerEndTurnSignal.connect(_on_playerEndTurnSignal)
	await get_tree().create_timer(1).timeout
	gameInstance[room_id].init()

func _on_playerDrawCardSignal(roomId : int, playerId : int, cardId : int):
	print(playerId, " draw card : ", cardId)
	if rooms[roomId][0] == playerId:
		print("its player 1 : {0} and {1}".format([str(rooms[roomId][0]), str(gameInstance[roomId].player1.playerId)]))
		rpc_id(rooms[roomId][0], "cardAddedInHand", cardId)
		rpc_id(rooms[roomId][1], "ennemiUpdateCardInHand", len(gameInstance[roomId].player2.hand))
	else:
		print("its player 2 : {0} and {1}".format([str(rooms[roomId][0]), str(gameInstance[roomId].player1.playerId)]))
		rpc_id(rooms[roomId][1], "cardAddedInHand", cardId)
		rpc_id(rooms[roomId][0], "ennemiUpdateCardInHand", len(gameInstance[roomId].player1.hand))

func _on_playerStartTurnSignal(roomId : int, playerId : int):
	pass

func _on_playerEndTurnSignal(roomId : int, playerId : int):
	pass

func start_game(room_id: int):
	var player_1 = rooms[room_id][0]
	var player_2 = rooms[room_id][1]
	rpc_id(player_1, "start_game", player_2, true)  # true = joueur 1 commence
	rpc_id(player_2, "start_game", player_1, false) # false = joueur 2 attend

@rpc("any_peer","call_remote","reliable")
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

@rpc("any_peer","call_remote","reliable")	
func waitOk():
	pass

@rpc("any_peer","call_remote","reliable")	
func joinRoom(_roomId : int):
	pass

@rpc("authority","call_remote","reliable")
func ennemiPlacedCard(cardId : int, slot : int):
	pass

@rpc("authority","call_remote","reliable")
func ennemiUpdateCardInHand(nbCard : int):
	pass

@rpc("authority","call_remote","reliable")
func cardAddedInHand(cardId : int):
	pass

@rpc("any_peer","call_remote","reliable")
func nextTurn(room_id : int, _peer_id:int):
	print("nextTurn")

@rpc("any_peer","call_remote","reliable")
func startOfRound():
	pass

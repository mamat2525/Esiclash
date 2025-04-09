# Server.gd
extends Node

const PORT = 4242
const MAX_PLAYERS = 100

var players = {} # Dictionnaire : peer_id -> player_info
var rooms = {}   # Dictionnaire : room_id -> [peer_id_1, peer_id_2]

func _ready():
	var server = ENetMultiplayerPeer.new()
	server.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = server
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)

func _player_connected(peer_id: int):
	print("Joueur connecté : ", peer_id)
	players[peer_id] = {"name": "Joueur_" + str(peer_id), "ready": false}
	rpc("update_lobby", players) # Envoie la liste des joueurs à tous les clients

func _player_disconnected(peer_id: int):
	print("Joueur déconnecté : ", peer_id)
	players.erase(peer_id)
	for room_id in rooms.keys():
		if peer_id in rooms[room_id]:
			rooms[room_id].erase(peer_id)
			if rooms[room_id].empty():
				rooms.erase(room_id)
			else:
				rpc_id(rooms[room_id][0], "opponent_disconnected")
	rpc("update_lobby", players)

@rpc("any_peer", "call_remote")
func create_room(peer_id: int):
	var room_id = randi() # ID unique pour la room
	rooms[room_id] = [peer_id]
	rpc_id(peer_id, "room_created", room_id)
	rpc("update_lobby", players)

@rpc("any_peer", "call_remote")
func join_room(peer_id: int, room_id: int):
	if room_id in rooms and rooms[room_id].size() < 2:
		rooms[room_id].append(peer_id)
		rpc_id(rooms[room_id][0], "player_joined", players[peer_id])
		rpc_id(peer_id, "room_joined", room_id, players[rooms[room_id][0]])
		if rooms[room_id].size() == 2:
			start_game(room_id)
	else:
		rpc_id(peer_id, "join_failed")

func start_game(room_id: int):
	var player_1 = rooms[room_id][0]
	var player_2 = rooms[room_id][1]
	rpc_id(player_1, "start_game", player_2, true)  # true = joueur 1 commence
	rpc_id(player_2, "start_game", player_1, false) # false = joueur 2 attend

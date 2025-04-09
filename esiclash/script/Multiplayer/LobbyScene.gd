# LobbyScene.gd
extends Control

const SERVER_IP = "127.0.0.1"
const PORT = 4242

var peer_id: int
var current_room_id: int = -1

@onready var player_list = $PlayerList
@onready var create_button = $CreateButton
@onready var join_button = $JoinButton
@onready var room_info = $RoomInfo

func _ready():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, PORT)
	multiplayer.multiplayer_peer = peer
	peer_id = multiplayer.get_unique_id()
	multiplayer.connected_to_server.connect(_connected_to_server)

func _connected_to_server():
	print("Connecté au serveur avec ID : ", peer_id)

@rpc("call_remote")
func update_lobby(players_data: Dictionary):
	player_list.clear()
	for p_id in players_data.keys():
		player_list.add_item(players_data[p_id]["name"] + " (ID: " + str(p_id) + ")")

func _on_CreateButton_pressed():
	rpc_id(1, "create_room", peer_id)

@rpc("call_remote")
func room_created(room_id: int):
	current_room_id = room_id
	room_info.text = "Room créée (ID: " + str(room_id) + "). En attente d’un adversaire..."
	create_button.disabled = true
	join_button.disabled = true

@rpc("call_remote")
func player_joined(player_info: Dictionary):
	room_info.text = "Adversaire rejoint : " + player_info["name"]

@rpc("call_remote")
func room_joined(room_id: int, host_info: Dictionary):
	current_room_id = room_id
	room_info.text = "Room rejointe (ID: " + str(room_id) + "). Hôte : " + host_info["name"]

@rpc("call_remote")
func join_failed():
	room_info.text = "Impossible de rejoindre la room."

func _on_JoinButton_pressed():
	var selected = player_list.get_selected_items()
	if selected.size() > 0:
		var selected_id = int(player_list.get_item_text(selected[0]).split("ID: ")[1].replace(")", ""))
		rpc_id(1, "join_room", peer_id, selected_id) # Simplification : ici on utilise l’ID du joueur comme room_id

@rpc("call_remote")
func start_game(opponent_id: int, is_first: bool):
	# Charger la scène de jeu
	var game_scene = load("res://GameScene.tscn").instantiate() # instantiate() remplace instance()
	game_scene.set_multiplayer_authority(1) # Le serveur garde le contrôle
	game_scene.opponent_id = opponent_id
	game_scene.is_first = is_first
	get_tree().root.add_child(game_scene)
	queue_free() # Supprime la scène de lobby

@rpc("call_remote")
func opponent_disconnected():
	room_info.text = "L’adversaire s’est déconnecté."
	create_button.disabled = false
	join_button.disabled = false
	current_room_id = -1

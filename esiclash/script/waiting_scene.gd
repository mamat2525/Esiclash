extends Control

var rotationActuelle : float = 0
@onready var waitlogo = $Container/WaitingAsset
@onready var label = $Label
var server

func _ready():
	ServerHandeler.serveur.peer_connected.connect(updateConnection)
	ServerHandeler.serveur.peer_disconnected.connect(updateConnection)
	ServerHandeler.roomJoined.connect(roomJoined)
	updateConnection()

func _process(delta: float) -> void:
	rotationActuelle += delta*3
	waitlogo.set_rotation(rotationActuelle)
	
func updateConnection(_id=0):
	while true:
		if ServerHandeler.serveur.get_connection_status() == ENetMultiplayerPeer.ConnectionStatus.CONNECTION_DISCONNECTED:
			label.set_text("Déconnecter")
		elif ServerHandeler.serveur.get_connection_status() == ENetMultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTING:
			label.set_text("En cours de connection")
		elif ServerHandeler.serveur.get_connection_status() == ENetMultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
			if !ServerHandeler.inWaitingList:
				ServerHandeler.rpc("wantToPlay", ServerHandeler.serveur.get_unique_id())
				label.set_text("Connecté")
			else:
				label.set_text("En attente d'adversaire")
		await get_tree().create_timer(1).timeout

func roomJoined():
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")

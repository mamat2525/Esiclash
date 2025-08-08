extends Control

var rotationActuelle : float = 0
@onready var waitlogo = $Container/WaitingAsset
@onready var label = $Label
var server

var inWaitingList = false

func _ready():
	#ServerHandeler.serveur.peer_connected.connect(updateConnection)
	#ServerHandeler.serveur.peer_disconnected.connect(updateConnection)
	#ServerHandeler.roomJoined.connect(roomJoined)
	updateConnection()

func _process(delta: float) -> void:
	rotationActuelle += delta*3
	waitlogo.set_rotation(rotationActuelle)
	
	for message in ServerHandeler.getNewMessage():
		match message[0]:
			"waitOk":
				inWaitingList = true
			"joinRoom":
				get_tree().change_scene_to_file("res://scene/game_scene.tscn")
			_ :
				print_debug("message inconnu : ", message)
	
func updateConnection(_id=0):
	while true:
		if !ServerHandeler.connected:
			label.set_text("Déconnecter")
			inWaitingList = false
		elif ServerHandeler.connected:
			if !inWaitingList:
				ServerHandeler.client.put_utf8_string("wantToPlay")
				label.set_text("Connecté")
			else:
				label.set_text("En attente d'adversaire")
		await get_tree().create_timer(1).timeout

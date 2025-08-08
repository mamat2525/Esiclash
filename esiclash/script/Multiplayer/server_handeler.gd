extends Node

var client := StreamPeerTCP.new()
var connected := false
var reconnect_delay := 1.0
var reconnect_timer := 0.0
var host := "127.0.0.1"
var port := 4242

var incomingMessage : Array = []
var isNewMessage = false
const messageDelimiter = ':'

func _ready():
	try_connect()

func try_connect():
	print("Tentative de connexion...")
	var err = client.connect_to_host(host, port)
	if err != OK:
		print("Erreur de connexion :", err)

func _process(delta):
	client.poll()
	var status = client.get_status()
	if not connected:
		if status == StreamPeerTCP.STATUS_CONNECTED:
			connected = true
			print("Connecté au serveur !")
		elif status == StreamPeerTCP.STATUS_NONE or status == StreamPeerTCP.STATUS_ERROR:
			reconnect_timer += delta
			if reconnect_timer >= reconnect_delay:
				reconnect_timer = 0.0
				client = StreamPeerTCP.new()
				try_connect()
		return
	else:
		# Déconnexion détectée
		if status != StreamPeerTCP.STATUS_CONNECTED:
			print("Déconnecté du serveur.")
			connected = false
		else:
			# Lecture de données serveur
			if client.get_available_bytes() > 0:
				isNewMessage = true
				var message = client.get_utf8_string()
				incomingMessage.append(message.split(messageDelimiter))


func getNewMessage():
	if isNewMessage:
		var temp = incomingMessage.duplicate(true)
		incomingMessage.clear()
		isNewMessage = false
		return temp
	else:
		return []

#extends Node
#
#const IP_ADDRESS = "127.0.0.1"
#const PORT = 4242
#
#var connected : bool = false
#var serveur : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
#
#var timer : Timer
#var timeoutTime : int = 10
#
#var inWaitingList : bool = false
#var roomId : int = -1
#signal roomJoined
#
#signal ennemiPlacedCardSignal(cardId : int, slot : int) #slot : 0 : objetEnnemi, 1 : esisarienEnnemi, (A rajouter dans le futur, si certaine carte peuvent être placé chez l'adversaire)
#signal ennemiUpdateCardInHandSignal(nbCard : int)
#signal cardAddedInHandSignal(cardId : int)
#signal startOfRoundSignal
#
#
#func _ready():
	#timer = Timer.new()
	#self.add_child(timer)
	#timer.one_shot = true
	#pass
	#
	#
#func _process(_delta):
	#if !connected and (serveur.get_connection_status() != ENetMultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTING or timer.get_time_left()==0.0): 
		#if serveur.get_connection_status() == ENetMultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
			#connected = true
			#print("connected! ", serveur.get_unique_id())
		#else:
			#print("not connected")
			#serveur = ENetMultiplayerPeer.new()
			#var err = serveur.create_client(IP_ADDRESS, PORT)
			#if err!=OK:
				#print("pas ok")
			#multiplayer.multiplayer_peer = serveur
			#timer.start(timeoutTime)
			#
#@rpc("any_peer","call_remote","reliable")
#func wantToPlay(_peer_id:int):
	#pass
#
#@rpc("authority","call_remote","reliable")
#func waitOk():
	#inWaitingList=true
#
#@rpc("any_peer","call_remote","reliable")	
#func joinRoom(roomId_ : int):
	#print("I ({0}) joined the room {1}".format([ServerHandeler.serveur.get_unique_id(), roomId_]))
	#roomId = roomId_
	#roomJoined.emit()
#
#@rpc("authority","call_remote","reliable")
#func ennemiPlacedCard(cardId : int, slot : int, emplacement : int):
	#ennemiPlacedCardSignal.emit(cardId, slot, emplacement)
#
#@rpc("authority","call_remote","reliable")
#func ennemiUpdateCardInHand(nbCard : int):
	#ennemiUpdateCardInHandSignal.emit(nbCard)
#
#@rpc("authority","call_remote","reliable")
#func cardAddedInHand(cardId : int):
	#cardAddedInHandSignal.emit(cardId)
#
#@rpc("any_peer","call_remote","reliable")
#func nextTurn(_peer_id:int):
	#pass
#
#@rpc("any_peer","call_remote","reliable")
#func startOfRound():
	#startOfRoundSignal.emit()

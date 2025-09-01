extends Node

class Client:
	var peer = null
	var roomId : int = -1
	func _init(_peer : StreamPeerTCP):
		peer = _peer

var server := TCPServer.new()
var clients: Array = []  # retients la liste des clients connecté

var port := 4242
const messageDelimiter = ':'

var rooms : Dictionary = {}   # Dictionnaire : room_id -> [peer_id_1, peer_id_2]
var gameInstance : Dictionary = {}
var waitingListe : Array = []

func _ready():
	var err = server.listen(port)
	if err != OK:
		print("[serveur] Erreur lors du démarrage du serveur :", err)
		return
	print("[serveur] Serveur en écoute sur le port ", port)
	get_tree().root.remove_child(ServerHandeler)

func _process(_delta):
	# Nouvelle connexion
	if server.is_connection_available():
		var new_client = Client.new(server.take_connection())
		clients.append(new_client)
		print("[serveur] Nouveau client connecté :", new_client)

	# Gérer chaque client
	var disconnectedClient = [] 
	
	for client : Client in clients:

		# Vérifier l'état de connexion
		if client.peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("[serveur] Client déconnecté : ", client.peer)
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
				if client.peer == gameInstance[client.roomId].player1.peer:
					gameInstance[client.roomId].newMessage(0, message)
				elif client.peer == gameInstance[client.roomId].player2.peer:
					gameInstance[client.roomId].newMessage(1, message)
				else:
					print_debug("[serveur] pb : le client n'est dans la room qu'il est sensé être")
			
	for client in disconnectedClient:
		clients.erase(client)


func create_room(joueur1: Client, joueur2:Client):
	var room_id = randi() # ID unique pour la room #TODO : faire un id vraiment unique...
	rooms[room_id] = [joueur1, joueur2]
	print("[serveur] room created : ", room_id, " :", joueur1, ", ", joueur2)
	
	joueur1.peer.put_utf8_string("joinRoom")
	joueur2.peer.put_utf8_string("joinRoom")
	
	joueur1.roomId = room_id
	joueur2.roomId = room_id
	
	gameInstance[room_id] = GameInstance.new(joueur1.peer, joueur2.peer, room_id)

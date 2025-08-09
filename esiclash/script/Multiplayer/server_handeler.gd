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

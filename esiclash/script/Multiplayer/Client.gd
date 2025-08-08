class_name Client

var peer : StreamPeerTCP
var roomId : int = -1

var incomingMessage : Array = []
var isNewMessage = false

func _init(peer_ : StreamPeerTCP) -> void:
	peer = peer_
	
func getNewMessage():
	if isNewMessage:
		var temp = incomingMessage.duplicate(true)
		incomingMessage.clear()
		isNewMessage = false
		return temp
	else:
		return []

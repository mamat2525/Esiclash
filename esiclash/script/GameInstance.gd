class_name GameInstance
# contient la logique d'une partie

var player1 : Player = Player.new()
var player2 : Player = Player.new()

var roomId : int

signal playerDrawCardSignal(roomId : int, playerId : int, cardId : int)
signal playerStartTurnSignal(roomId : int, playerId : int)
signal playerEndTurnSignal(roomId : int, playerId : int)

func _init(playerId1 : int, playerId2 : int, roomId_ : int):
	player1.playerId = playerId1
	player2.playerId = playerId2
	roomId = roomId_
	
	
func init():
	for i in range(30):
		var card = randi() % 180
		player1.deck.append(card)
	for i in range(30):
		var card = randi() % 180
		player2.deck.append(card)
	
	
	# Mélanger les decks
	player1.deck.shuffle()
	player2.deck.shuffle()
	
	# Piocher 5 cartes
	for i in 5:
		draw_card(player2)
		draw_card(player1)
		
	
	if randi() % 2:
		playerStartTurnSignal.emit(roomId, player1.playerId)
		playerEndTurnSignal.emit(roomId, player2.playerId)
	else:
		playerStartTurnSignal.emit(roomId, player2.playerId)
		playerEndTurnSignal.emit(roomId, player1.playerId)
	
	
func draw_card(p: Player):
	if p.hand.size() < 8 and p.deck.size() > 0:
		var card = p.deck.pop_back()
		p.hand.append(card)
		print_debug(p.playerId)
		playerDrawCardSignal.emit(roomId, p.playerId, card)

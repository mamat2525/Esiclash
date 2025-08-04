# Player.gd
class_name Player
extends Node

enum PlayerType {ALLIE, ENNEMIE}

var health: int = 30
var energy: int = 10
var deck: Array = []       # Liste de Card
var hand: Array = []       # Liste de Card
var graveyard: Array = []  # Liste de Card
var banished: Array = []   # Liste de Card
var esisarien: Array = [null, null, null, null, null]
var objet: Array = [null, null, null, null, null]
var esisarien_slots: Slots
var object_slots: Slots
var prof_card: Card = null
var playerId : int

func init(playerType : PlayerType, EsisarienSlots : Node, ObjetSlots : Node):
	esisarien_slots = Slots.new(EsisarienSlots, Card.CardType.ESISARIEN, playerType)
	object_slots = Slots.new(ObjetSlots, Card.CardType.OBJET, playerType)

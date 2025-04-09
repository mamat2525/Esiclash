# Player.gd
class_name Player
extends Node

var health: int = 30
var energy: int = 10
var deck: Array = []       # Liste de Card
var hand: Array = []       # Liste de Card
var graveyard: Array = []  # Liste de Card
var banished: Array = []   # Liste de Card
var esisarien_field: Array = [] # 5 emplacements (null si vide)
var object_field: Array = []    # 5 emplacements (null si vide)
var prof_card: Card = null

func _init():
	esisarien_field.resize(5)
	object_field.resize(5)

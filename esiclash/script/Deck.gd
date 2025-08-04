class_name Deck
extends Node


var deckname : String = ""
var deck : Array
var playable : bool = false

func _init(_deckname : String, _deck : Array):
	deckname = _deckname
	deck = _deck

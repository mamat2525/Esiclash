class_name Slots
extends Node

const espacementEntreCarte = 10

var objectSlot : Node
var slots = [null, null, null, null, null]

var type : Card.CardType
var joueur : Player.PlayerType

var GameScene : Node

func _init(objectSlot_, type_, joueur_):
	objectSlot = objectSlot_
	type = type_
	joueur = joueur_
	GameScene=objectSlot.get_parent().get_parent()
	
func placerCarte(carte : Card, emplacement : int):
	if slots[emplacement] != null:
		push_error("impossible de placer cette carte : l'emplacement n'est pas vide")
		return
	if carte.type != type:
		push_error("impossible de placer cette carte : la carte n'est pas du même type que le conteneur")
		return
	if emplacement > 4 || emplacement < 0:
		push_error("impossible de placer cette carte : l'emplacement n'est pas valide")
		return
	
	carte.beforeCard = null
	carte.nextCard = null
	
	slots[emplacement] = carte
	objectSlot.add_child(carte)
	carte.setPos(Vector2((Card.baseSize.x+espacementEntreCarte)*emplacement, 0))
	carte.hooverMode = Card.HooverMode.CENTRER

var hoverlayList = []

func placerHoverlayDisponible(emplacement:int, card:TextureButton):
	var hoverlay = load("res://scene/objets/hoverlay_place_possible.tscn").instantiate()
	hoverlay.set_card(card, emplacement)
	hoverlay.set_position(Vector2((Card.baseSize.x+espacementEntreCarte)*emplacement-10,-10))
	objectSlot.add_child(hoverlay)
	hoverlayList.append(hoverlay)
	hoverlay.connect("cardPlaced", GameScene._on_card_placed)

func supprHoverlay():
	for obj in hoverlayList:
		objectSlot.remove_child(obj)
	hoverlayList.clear()

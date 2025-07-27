class_name Slots
extends Node

const espacementEntreCarte = 10

var objectSlot : Node
var slots = [null, null, null, null, null]

var type : Card.CardType
enum JoueurType {ALLIE, ENNEMI}
var joueur : JoueurType

func _init(objectSlot_, type_, joueur_):
	objectSlot = objectSlot_
	type = type_
	joueur = joueur_
	
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
	
	slots[emplacement] = carte
	objectSlot.add_child(carte)
	carte.setPos(Vector2((Card.baseSize.x+espacementEntreCarte)*emplacement, 0))
	carte.hooverMode = Card.HooverMode.CENTRER

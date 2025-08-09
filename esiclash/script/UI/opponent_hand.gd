extends Control

var fakeCard = load("res://scene/opponent_card.tscn")
var nbActuelle : int = 0
var listChild : Array

func setCard(nb : int):
	listChild = self.get_children()
	for i in range(nbActuelle-nb):
		self.remove_child(listChild[i])
	for i in range(nb-nbActuelle):
		self.add_child(fakeCard.instantiate())
		
	listChild = self.get_children()
	nbActuelle=nb
	actuPos()
	
func actuPos():
	var offset = (self.get_size().x-(nbActuelle)*CardUi.baseSize.x/2)/2
	for nb in range(nbActuelle):
		listChild[nb].set_position(Vector2(offset+CardUi.baseSize.x/2*(nb-1), 0))
		

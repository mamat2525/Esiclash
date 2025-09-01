extends TextureButton

signal cardPlaced(emplacement:int)

var emplacement : int

var vide : bool = true

func set_card(card : Node, emplacement_ : int):
	self.emplacement=emplacement_
	if card != null:
		$"cardPreview".set_texture(card.get_child(0).get_texture())
		vide = false
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	$"cardPreview".hide()

func _on_mouse_entered() -> void:
	$"cardPreview".show()

func _on_mouse_exited() -> void:
	$"cardPreview".hide()


func _on_button_down() -> void:
	if !vide:
		cardPlaced.emit(emplacement)

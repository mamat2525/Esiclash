extends TextureButton

signal cardPlaced(emplacement:int)

var emplacement : int

func set_card(card:TextureButton, emplacement_ : int):
	self.emplacement=emplacement_
	$"cardPreview".set_texture(card.get_texture_normal())
	$"cardPreview".hide()

func _on_mouse_entered() -> void:
	$"cardPreview".show()

func _on_mouse_exited() -> void:
	$"cardPreview".hide()


func _on_button_down() -> void:
	cardPlaced.emit(emplacement)

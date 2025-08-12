extends Node2D

var deckList = []
#passer la variable dans un script global afin de l'utilser partout
var selectedDeck = []

@onready var button_new = $Button_new_deck
@onready var deck_container = $Deck_container
@onready var selected_deck = $SelectedDeck
@onready var line_edit = $LineEdit

func _ready():
	#appeler fonction création d'interface de deck pour chaque menbre de decklist
	button_new.pressed.connect(_on_new_deck_pressed)
	deck_container.columns = 4
	
	#créer l'interface des deck deja existant au chargement de la scène
	for i in range(deckList.size()):
		_interface_new_deck(deckList[i])
	
	
func _on_new_deck_pressed():
	if deckList.size() < 12 :
		#renvoie écran création nouveau deck
		var label_text = line_edit.text.strip_edges()
		var new_deck_content = []
		for i in range(30):
			new_deck_content.append(randi()%180)
		var new_deck = Deck.new(label_text,new_deck_content)
		new_deck.playable = true
		deckList.append(new_deck)
		_interface_new_deck(new_deck)
		line_edit.clear()

func _interface_new_deck(new_deck:Deck):
	var new_container = HBoxContainer.new()
	var container_label = VBoxContainer.new()
	var container_option = VBoxContainer.new()
	var new_button = Button.new()
	var mod_button = Button.new()
	var suppr_button = Button.new()
	var label_deck = Label.new()
	var popup_suppr = PopupPanel.new()
	
	#Allocation d'espace pour les nouveaus boutons et mise en page popup suppresion
	new_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_suppr.size = Vector2(400,200)
	popup_suppr.transparent = false
	
	#Interface selection de deck
	label_deck.text = new_deck.deckname
	label_deck.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var logo = load(CardData.card[new_deck.deck[0]]["file"]) as Texture2D
	var logo_bonne_taille = redimensionner_texture(logo,Vector2(100,150))
	new_button.icon = logo_bonne_taille

	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(func(): _on_select_button_pressed(new_deck.deckname))
	container_label.add_child(new_button)
	container_label.add_child(label_deck)
	
	#Interface modification de deck
	mod_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mod_button.text = "mod"
	mod_button.set_meta("deck",new_deck.deckname)
	mod_button.pressed.connect(func(): _on_modify_button_pressed(mod_button.get_meta("deck")))
	container_option.add_child(mod_button)
	
	#Interface suppression de deck
	suppr_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	suppr_button.text = "suppr"
	suppr_button.set_meta("deck",new_deck.deckname)
	suppr_button.pressed.connect(func(): _on_suppr_button_pressed(suppr_button,suppr_button.get_meta("deck"),popup_suppr))
	container_option.add_child(suppr_button)
	
	new_container.add_child(container_label)
	new_container.add_child(container_option)
	deck_container.add_child(new_container)
	new_container.add_child(popup_suppr)

	
func _on_select_button_pressed(deckName:String):
	for i in range(deckList.size()):
		if deckName == deckList[i].deckname :
			if deckList[i].playable == true:
				selected_deck.text = deckName + " " + str(deckList[i].deck)
				selectedDeck = deckList[i].deck
			else:
				selected_deck.text = "deck non jouable"

func _on_modify_button_pressed(deckname:String):
	#renvoie à la création de deck mais avec les données du deck chargée
	pass
	
func _on_suppr_button_pressed(to_delete:Button,deckName:String,popup_suppr:PopupPanel):
	var final_suppr_button = Button.new()
	var text_suppr = Label.new()
	var cancel_suppr_button = Button.new()
	var container_popup = VBoxContainer.new()
	var button_container_popup = HBoxContainer.new()
	
	#mise en page des éléments de la popup
	cancel_suppr_button.text = "Annuler"
	final_suppr_button.text = "Supprimer"
	text_suppr.text = "Voulez-vous supprimer ce deck ?"
	final_suppr_button.pressed.connect(func(): _on_final_suppr_pressed(to_delete,deckName))
	cancel_suppr_button.pressed.connect(func(): _on_cancel_suppr_pressed(popup_suppr))
	
	button_container_popup.alignment = BoxContainer.ALIGNMENT_CENTER
	cancel_suppr_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	final_suppr_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container_popup.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_suppr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_suppr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_suppr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	container_popup.add_child(text_suppr)
	button_container_popup.add_child(cancel_suppr_button)
	button_container_popup.add_child(final_suppr_button)
	container_popup.add_child(button_container_popup)
	popup_suppr.add_child(container_popup)
	popup_suppr.popup_centered()
	
func _on_final_suppr_pressed(to_delete:Button,deckName:String):
	#supprime l'affichage
	to_delete.get_parent().get_parent().queue_free()
	
	#supprime le deck
	for i in range(deckList.size() - 1, -1, -1):
		if deckName == deckList[i].deckname :
			deckList.remove_at(i)
		
func _on_cancel_suppr_pressed(popup_suppr:PopupPanel):
	popup_suppr.hide()

func redimensionner_texture(texture: Texture2D, taille: Vector2) -> Texture2D:
	var image = texture.get_image()
	image.resize(taille.x, taille.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

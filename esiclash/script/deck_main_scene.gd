extends Node2D

var deckList = []
#passer la variable dans un script global afin de l'utilser partout
var selectedDeck = []

@onready var button_new = $Button_new_deck
@onready var deck_container = $Deck_container
@onready var selected_deck = $SelectedDeck
@onready var line_edit = $LineEdit

func _ready():
	button_new.pressed.connect(_on_new_deck_pressed)
	
	
func _on_new_deck_pressed():
	#renvoie écran création nouveau deck
	var label_text = line_edit.text.strip_edges()
	var new_deck_content = []
	for i in range(30):
		new_deck_content.append(randi()%180)
	var new_deck = Deck.new(label_text,new_deck_content)
	new_deck.playable = true
	deckList.append(new_deck)

	#crée interface pour nouveau deck
	var new_container = HBoxContainer.new()
	var new_button = Button.new()
	var mod_button = Button.new()
	var suppr_button = Button.new()
	
	#Allocation d'espace pour les nouveaus boutons
	new_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	#Interface selection de deck
	new_button.text = new_deck.deckname
	var logo = load(CardData.card[new_deck.deck[0]]["file"]) as Texture2D
	var logo_bonne_taille = redimensionner_texture(logo,Vector2(100,150))
	new_button.icon = logo_bonne_taille

	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(func(): _on_select_button_pressed(new_deck.deckname))
	new_container.add_child(new_button)
	
	#Interface modification de deck
	mod_button.text = "mod"
	mod_button.set_meta("deck",new_deck.deckname)
	mod_button.pressed.connect(func(): _on_modify_button_pressed(mod_button.get_meta("deck")))
	new_container.add_child(mod_button)
	
	#Interface suppression de deck
	suppr_button.text = "suppr"
	suppr_button.set_meta("deck",new_deck.deckname)
	suppr_button.pressed.connect(func(): _on_suppr_button_pressed(suppr_button,suppr_button.get_meta("deck")))
	new_container.add_child(suppr_button)
	
	deck_container.add_child(new_container)
	line_edit.clear()
	
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
	
func _on_suppr_button_pressed(to_delete:Button,deckName:String):
	#supprime l'affichage
	to_delete.get_parent().queue_free()
	
	#supprime le deck
	for i in range(deckList.size() - 1, -1, -1):
		if deckName == deckList[i].deckname :
			deckList.remove_at(i)
		
	#A ajouter popup pour valider suppression
	
func redimensionner_texture(texture: Texture2D, taille: Vector2) -> Texture2D:
	var image = texture.get_image()
	image.resize(taille.x, taille.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

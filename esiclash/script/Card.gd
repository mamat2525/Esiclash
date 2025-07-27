# Card.gd
class_name Card
extends TextureRect

const baseSize = Vector2(140,200)
var basePos = Vector2(0,0)

const espacementEntreCarte = 5

enum CardType { ESISARIEN, OBJET, ACTION, PROF }
enum EsisarienAttribute { CHARGE, PERCANT, RAGE, SNIPER, INVULNERABLE, INTANGIBLE }
enum ActionType { RAPIDE, LOURDE, CONTRE }
enum ObjectType { CONTINU, EQUIPEMENT }

enum HooverState {PETIT, GRANDIT, GRAND, RETRECIT}
var hooverState : HooverState = HooverState.PETIT
var hooverScale : float = 1
enum HooverMode {CENTRER, DECALER}
var hooverMode : HooverMode = HooverMode.DECALER

enum PushDirection {GAUCHE, CENTRE_A_GAUCHE, GAUCHE_A_CENTRE, CENTRE, CENTRE_A_DROITE, DROITE_A_CENTRE, DROITE}
var pushDir : PushDirection = PushDirection.CENTRE
var pushPos : float = 0

var beforeCard = null
var nextCard = null

var id: int                # Identifiant unique
var card_name: String           # Nom de la carte
var type: CardType         # Type principal
var is_unique: bool = false # Carte unique ou commune
var coutBase : int
var baseAtk : int
var baseDef : int

# Propriétés spécifiques à Esisarien
var atk: int = 0
var def: int = 0
var attributes: Array = [] # Liste d'attributs (ex: [CHARGE, PERCANT])
var effect_text: String = ""    # Description de l'effet (ex: "Dernier Souffle: pioche 1 carte")
var effects: Array = [] # Liste d'effets sous forme de tableau
var is_face_down: bool = false
var positionCombat: String = "attack" # "attack" ou "defense"
var can_attack: bool = false

# Propriétés spécifiques à Objet
var object_type: ObjectType

# Propriétés spécifiques à Action
var action_type: ActionType

func _init(idCarte:int):
	var card = CardData.card[idCarte]
	id = idCarte
	name = card["name"]
	type = card["type"]
	if type != CardType.PROF:
		coutBase = card["cout"]
		
	if type == CardType.ESISARIEN:
		baseAtk = card["atk"]
		baseDef = card["def"]
	self.set_texture(load(card["file"]))
	self.set_expand_mode(TextureRect.EXPAND_IGNORE_SIZE)
	self.set_stretch_mode(TextureRect.STRETCH_SCALE)
	
	self.set_position(basePos)
	self.set_size(baseSize)
	self.show()
	
	self.connect("mouse_entered", _on_mouse_entered)
	self.connect("mouse_exited", _on_mouse_exited)

func _process(delta: float) -> void:
	if (hooverState == HooverState.GRANDIT or hooverState == HooverState.RETRECIT or (pushDir not in [PushDirection.GAUCHE, PushDirection.CENTRE, PushDirection.DROITE])):
		if (hooverState == HooverState.GRANDIT):
			hooverScale+=delta*20
			if(hooverScale>2.5):
				hooverScale=2.5
				hooverState = HooverState.GRAND
			self.set_size(baseSize*hooverScale)
			
		elif (hooverState == HooverState.RETRECIT):
			hooverScale-=delta*20
			if(hooverScale<1):
				hooverScale=1
				hooverState = HooverState.PETIT
			self.set_size(baseSize*hooverScale)
	
		if pushDir not in [PushDirection.GAUCHE, PushDirection.CENTRE, PushDirection.DROITE]:
			var direction = -1
			if pushDir==PushDirection.GAUCHE_A_CENTRE or pushDir==PushDirection.CENTRE_A_DROITE:
				direction=1
			
			pushPos+=delta*direction*1000
			
			if (pushDir==PushDirection.GAUCHE_A_CENTRE and pushPos>0) or (pushDir==PushDirection.DROITE_A_CENTRE and pushPos<0):
				pushDir=PushDirection.CENTRE
				pushPos=0
			elif pushDir==PushDirection.CENTRE_A_GAUCHE and pushPos<-baseSize.x*0.75-(espacementEntreCarte*direction):
				pushDir=PushDirection.GAUCHE
				pushPos=-baseSize.x*0.75-(espacementEntreCarte*direction)
			elif pushDir==PushDirection.CENTRE_A_DROITE and pushPos>baseSize.x*0.75-(espacementEntreCarte*direction):
				pushDir=PushDirection.DROITE
				pushPos=baseSize.x*0.75-(espacementEntreCarte*direction)
				
				
		if hooverMode == HooverMode.DECALER:
			self.set_position(basePos+Vector2(pushPos+(baseSize.x-baseSize.x*hooverScale)/2,baseSize.y-baseSize.y*hooverScale))
		else : 
			self.set_position(basePos+Vector2(pushPos,0) + (baseSize - baseSize*hooverScale)/2)

func _on_mouse_entered():
	hooverState = HooverState.GRANDIT
	self.move_to_front()
	self.z_index = 5
	if nextCard != null:
		nextCard.push(PushDirection.DROITE)
	if beforeCard != null:
		beforeCard.push(PushDirection.GAUCHE)
	
func _on_mouse_exited():
	hooverState = HooverState.RETRECIT
	self.z_index = 0
	if nextCard != null:
		nextCard.unPush(PushDirection.DROITE)
	if beforeCard != null:
		beforeCard.unPush(PushDirection.GAUCHE)

func setPos(pos : Vector2):
	basePos = pos
	self.set_position(basePos+Vector2(0,baseSize.y-baseSize.y*hooverScale))

func push(direction):
	if direction==PushDirection.DROITE:
		if nextCard != null:
			nextCard.push(direction)
		pushDir=PushDirection.CENTRE_A_DROITE
		
	elif direction==PushDirection.GAUCHE:
		if beforeCard != null:
			beforeCard.push(direction)
		pushDir=PushDirection.CENTRE_A_GAUCHE

func unPush(direction):
	if direction==PushDirection.DROITE:
		if nextCard != null:
			nextCard.unPush(direction)
		pushDir=PushDirection.DROITE_A_CENTRE
		
	elif direction==PushDirection.GAUCHE:
		if beforeCard != null:
			beforeCard.unPush(direction)
		pushDir=PushDirection.GAUCHE_A_CENTRE
		

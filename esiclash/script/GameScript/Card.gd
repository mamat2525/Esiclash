# Card.gd
class_name Card


enum CardType { ESISARIEN, OBJET, ACTION, PROF }
enum EsisarienAttribute { CHARGE, PERCANT, RAGE, SNIPER, INVULNERABLE, INTANGIBLE }
enum ActionType { RAPIDE, LOURDE, CONTRE }
enum ObjectType { CONTINU, EQUIPEMENT }

var id: int                	# Identifiant unique
var card_name: String      	# Nom de la carte
var type: CardType         	# Type principal
var is_unique: bool = false	# Carte unique ou commune
var coutBase : int
var baseAtk : int
var baseDef : int

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

func _init(idCarte:int=0):
	var card = CardData.card[idCarte]
	id = idCarte
	card_name = card["name"]
	type = card["type"]
	if type != CardType.PROF:
		coutBase = card["cout"]
		
	if type == CardType.ESISARIEN:
		baseAtk = card["atk"]
		baseDef = card["def"]

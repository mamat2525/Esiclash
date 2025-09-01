class_name CardUi
extends Button

const baseSize = Vector2(140,200)
var basePos = Vector2(0,0)

const espacementEntreCarte = 5

enum HooverState {PETIT, GRANDIT, GRAND, RETRECIT}
var hooverState : HooverState = HooverState.PETIT
var hooverScale : float = 1
enum HooverMode {CENTRER, DECALER}
var hooverMode : HooverMode = HooverMode.DECALER

var survoler : bool = false
var timer : Timer = null
const timerTrigger = 0.15

enum PushDirection {GAUCHE, CENTRE_A_GAUCHE, GAUCHE_A_CENTRE, CENTRE, CENTRE_A_DROITE, DROITE_A_CENTRE, DROITE}
var pushDir : PushDirection = PushDirection.CENTRE
var pushPos : float = 0

var beforeCard = null
var nextCard = null

signal carteCliquee(card : Card, focusGagner : bool)
var selectionner : bool = false

#info relative à la carte. Remplacer tout ca, si ca devient redondant, par une var card : Card qui retient tout
var type: Card.CardType
var card

var reveler : bool = false
var peutReveler : bool = false
var peutAttack : bool = false

enum FightPosition {ATTACK, DEFENSE, WAITACTION}

var fightPosition : FightPosition = FightPosition.WAITACTION

var placer : bool = false

@onready var texture = $Texture
@onready var cardMenu = $Texture/CardMenu
@onready var hoverlay = $hoverlay
@onready var game_scene = $/root/GameScene
@onready var attackBut = $Texture/CardMenu/AttackButton
@onready var showBut = $Texture/CardMenu/ShowButton
@onready var defBut = $Texture/CardMenu/DefendButton

var hoverlayAttack = preload("res://assets/hoverlayAttack.png")
var hoverlayDefense = preload("res://assets/hoverlayDefense.png")
var hiddedHoverlay = preload("res://assets/hiddedHoverlay.png")

var ennemi : bool = false
var emplacementDansSlot : int

var attacking : bool = false

func _ready():
	self.set_position(basePos)
	self.set_size(baseSize)
	
	self.connect("mouse_entered", _on_mouse_entered)
	self.connect("mouse_exited", _on_mouse_exited)
	self.connect("button_down", _on_mouse_button_down)
	self.connect("focus_exited", _on_focus_exited)
	
func set_card(idCarte):
	card = CardData.card[idCarte]
	type = card["type"]
	if !self.is_node_ready():
		await self.ready
	self.texture.set_texture(load(card["file"]))

func _process(delta: float) -> void:
	if timer!=null and timer.get_time_left()==0.0:
		agrandir()
		timer.queue_free()
	
	if (hooverState == HooverState.GRANDIT or hooverState == HooverState.RETRECIT or (pushDir not in [PushDirection.GAUCHE, PushDirection.CENTRE, PushDirection.DROITE])):
		actuPosition(delta)

func actuPosition(delta):
	if (hooverState == HooverState.GRANDIT):
		hooverScale+=delta*20
		if(hooverScale>2.5):
			hooverScale=2.5
			hooverState = HooverState.GRAND
		texture.set_size(baseSize*hooverScale)
		
	elif (hooverState == HooverState.RETRECIT):
		hooverScale-=delta*20
		if(hooverScale<1):
			hooverScale=1
			hooverState = HooverState.PETIT
		texture.set_size(baseSize*hooverScale)

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
		#self.set_position(basePos+Vector2(pushPos+(baseSize.x-baseSize.x*hooverScale)/2,baseSize.y-baseSize.y*hooverScale+selectionnerOffset))
		self.set_position(basePos+Vector2(pushPos,0))
		texture.set_position(Vector2((baseSize.x-baseSize.x*hooverScale)/2,baseSize.y-baseSize.y*hooverScale))
	else : 
		self.set_position(basePos+Vector2(pushPos,0))
		texture.set_position((baseSize - baseSize*hooverScale)/2)

func _on_mouse_entered():
	timer = Timer.new()
	self.add_child(timer)
	timer.one_shot = true
	timer.start(timerTrigger)
	
func agrandir():
	hooverState = HooverState.GRANDIT
	self.z_index = 5
	hoverlay.hide()
	if nextCard != null:
		nextCard.push(PushDirection.DROITE)
	if beforeCard != null:
		beforeCard.push(PushDirection.GAUCHE)
		
	
func _on_mouse_exited():
	if timer!=null:
		timer.queue_free()
	if !selectionner:
		hoverlay.show()
	hooverState = HooverState.RETRECIT
	self.z_index = 0
	if nextCard != null:
		nextCard.unPush(PushDirection.DROITE)
	if beforeCard != null:
		beforeCard.unPush(PushDirection.GAUCHE)

func _on_mouse_button_down():
	self.selectionner=true
	carteCliquee.emit(self, true)
	if ennemi:
		game_scene.ennemiIsSelected(emplacementDansSlot)
	else:
		if placer and game_scene.current_turn:
			if fightPosition == FightPosition.WAITACTION:
				if peutReveler and !reveler:
					cardMenu.selectionner(true)
				if reveler:
					if peutAttack:
						cardMenu.selectionner(false, true, true)
					else:
						cardMenu.selectionner(false, true)
			else:
				cardMenu.selectionner()

func setPos(pos : Vector2):
	basePos = pos
	self.set_position(basePos+Vector2(0,baseSize.y-baseSize.y*hooverScale))
	
func cartePlaced(pos : Vector2, emplacement : int, ennemi_ : bool = false):
	setPos(pos)
	hooverMode = CardUi.HooverMode.CENTRER
	placer = true
	emplacementDansSlot = emplacement
	actuPosition(1)
	ennemi = ennemi_
	if !ennemi:
		hoverlay.set_texture(hiddedHoverlay)


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


func _on_focus_exited():
	carteCliquee.emit(self, false)
	await get_tree().process_frame #pas touche, ca corrige plein de bugs (d'affichage (de toute façon, ca fait que l'affichage ici)) et ca marche mieux (c'est un peu le principe de corriger des bugs)
	if !attackBut.has_focus() and !showBut.has_focus() and !defBut.has_focus():
		selectionner=false
		actuPosition(0)
		hoverlay.show()
		cardMenu.selectionner()
		if attacking:
			game_scene.cardStopWantToFight(emplacementDansSlot)
			attacking = false
			

func _on_show_button_button_down() -> void:
	self.reveler = true
	self.setFightPosition(FightPosition.DEFENSE)
	ServerHandeler.client.put_utf8_string("revealCard:{0}".format([str(emplacementDansSlot)]))

func _on_defend_button_button_down() -> void:
	self.setFightPosition(FightPosition.DEFENSE)
	ServerHandeler.client.put_utf8_string("setFightPos:{0}:def".format([str(emplacementDansSlot)]))

func _on_attack_button_button_down() -> void:
	attacking = true
	game_scene.cardWantToFight(emplacementDansSlot)
	hoverlay.set_texture(hoverlayAttack)
	game_scene.player.esisarien_slots.supprHoverlay()
	game_scene.opponent.esisarien_slots.supprHoverlay()
	game_scene.player.esisarien_slots.placerHoverlayDisponible(emplacementDansSlot)
	for i in range(5):
		if game_scene.opponent.esisarien_slots.slots[i] != null:
			game_scene.opponent.esisarien_slots.placerHoverlayDisponible(i)

func setFightPosition(pos : FightPosition):
	fightPosition = pos
	if pos == FightPosition.WAITACTION:
		if reveler:
			hoverlay.set_texture(null)
	elif pos == FightPosition.DEFENSE:
		hoverlay.show()
		hoverlay.set_texture(hoverlayDefense)
	elif pos == FightPosition.ATTACK:
		hoverlay.show()
		hoverlay.set_texture(hoverlayAttack)
	else:
		push_error("fightPosition inconnu dans setFightPosition")
		
func hasAttacked():
	setFightPosition(FightPosition.ATTACK)
	game_scene.player.esisarien_slots.supprHoverlay()
	game_scene.opponent.esisarien_slots.supprHoverlay()
	cardMenu.selectionner()
	#ServerHandeler.client.put_utf8_string("setFightPos:{0}:atk".format([str(emplacementDansSlot)])) # a enlever si pas de probleme

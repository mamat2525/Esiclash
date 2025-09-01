extends Control

@onready var attackIcon = $AttackButton
@onready var defendIcon = $DefendButton
@onready var showIcon = $ShowButton
@onready var colorRect = $ColorRect

enum button {SHOW, DEFEND, ATTACK}

func selectionner(canShow = false, canDefend = false, canAttack = false):
	if canAttack or canDefend or canShow:
		show()
		if canShow:
			showIcon.show()
		if canAttack:
			attackIcon.show()
		if canDefend:
			defendIcon.show()
	else:
		colorRect.hide()
		attackIcon.hide()
		defendIcon.hide()
		showIcon.hide()

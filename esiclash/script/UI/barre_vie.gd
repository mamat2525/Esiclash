extends TextureProgressBar

const color = [Color(0,0.62,0), Color(0.86,0.28,0), Color(1,0.1,0.1), Color(0,0,0,0)]
#			  vert     			orange   			rouge    			transparent

var actualHealth = 30

func _ready():
	update_health(30)

func update_health(health : int):
	actualHealth = health
	if health > 20:
		value = health - 20
		set_tint_progress(color[0])
		set_tint_under(color[1])
	elif health > 10: 
		value = health - 10
		set_tint_progress(color[1])
		set_tint_under(color[2])
	elif health > 0:
		value = health
		set_tint_progress(color[2])
		set_tint_under(color[3])
	else:
		print("ploup, plus de vie")
		value = health
		set_tint_progress(color[2])
		set_tint_under(color[3])

##pour test de l'affichage de la vie
#var progress = 0.
#
#func _process(delta: float) -> void:
	#progress+=delta
	#if progress > 1.0:
		#update_health(actualHealth-1)
		#progress = 0

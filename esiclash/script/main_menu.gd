extends Node2D

func _ready():
	
	
	var args = OS.get_cmdline_args()
	await get_tree().process_frame
	get_window().set_size(Vector2(1600,920))
	get_window().set_mode(Window.MODE_WINDOWED)
	get_window().set_position(Vector2(320, 180))
	if args[1] == "serveur":
		get_window().set_mode(Window.MODE_MINIMIZED)
		get_tree().change_scene_to_file("res://scene/serveur.tscn")
		

func _on_boutton_jouer_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/waitingScene.tscn")

func _on_boutton_deck_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/deck_main_scene.tscn")

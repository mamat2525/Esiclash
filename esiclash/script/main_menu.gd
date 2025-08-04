extends Node2D

func _ready():
	var args = OS.get_cmdline_args()
	if args[1] == "serveur":
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://scene/serveur.tscn")

func _on_boutton_jouer_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/waitingScene.tscn")

func _on_boutton_deck_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/deck_main_scene.tscn")

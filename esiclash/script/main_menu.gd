extends Node2D



func _on_boutton_jouer_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/game_scene.tscn")


func _on_boutton_deck_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/deck_main_scene.tscn")

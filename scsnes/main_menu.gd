extends Control

@onready var clock = $"CLOCK BG"
@onready var play_button = $CenterContainer/VBoxContainer/PLAY
@onready var settings_button = $CenterContainer/VBoxContainer/SETTINGS
@onready var credits_button = $CenterContainer/VBoxContainer/CREDITS
@onready var quit_button = $CenterContainer/VBoxContainer/QUIT

var clock_tween: Tween


func _ready() -> void:
	var buttons = [
		play_button,
		settings_button,
		credits_button,
		quit_button
	]

	for button in buttons:
		button.mouse_entered.connect(_on_button_hover)
		button.mouse_exited.connect(_on_button_unhover)


func _on_button_hover() -> void:
	animate_clock(Vector2(6.25, 6.25))


func _on_button_unhover() -> void:
	animate_clock(Vector2(6.0, 6.0))


func animate_clock(target_scale: Vector2) -> void:
	if clock_tween:
		clock_tween.kill()

	clock_tween = create_tween()
	clock_tween.set_trans(Tween.TRANS_QUAD)
	clock_tween.set_ease(Tween.EASE_OUT)
	clock_tween.tween_property(clock, "scale", target_scale, 0.15)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scsnes/ntest.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scsnes/settings.tscn")

extends Control

@onready var knife = $KNIFE


func _ready() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		knife,
		"scale",
		Vector2(3.7, 3.7),
		0.8
	)

	tween.tween_property(
		knife,
		"scale",
		Vector2(3.5, 3.5),
		0.8
	)
